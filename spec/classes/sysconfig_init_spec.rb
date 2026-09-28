require 'spec_helper'

describe 'useradd::sysconfig_init' do
  let(:facts) { on_supported_os.first[1].merge(init_systems: ['systemd']) }

  def managing_resources
    catalogue.resources.select { |r| ['File', 'Exec'].include?(r.type) }
  end

  context 'with default parameters' do
    it { is_expected.to compile.with_all_deps }
    it { expect(managing_resources).to be_empty }
    it { is_expected.not_to contain_class('systemd') }
  end

  context 'with every /etc/sysconfig/init setting' do
    let(:params) do
      {
        bootup: 'color',
        res_col: 60,
        move_to_col: '"echo -en \\033[${RES_COL}G"',
        setcolor_success: 'green',
        setcolor_failure: '"echo -en \\033[0;41m"',
        loglvl: 3,
        prompt: false,
        autoswap: true,
        mode: '0644',
        purge: true,
      }
    end

    def setting(key)
      "/etc/sysconfig/init #{key}"
    end

    it { is_expected.to compile.with_all_deps }

    it do
      is_expected.to contain_augeas(setting('BOOTUP')).with(
        incl: '/etc/sysconfig/init',
        lens: 'Shellvars.lns',
        changes: 'set BOOTUP "color"',
      )
    end

    it { is_expected.to contain_augeas(setting('RES_COL')).with_changes('set RES_COL "60"') }
    it { is_expected.to contain_augeas(setting('MOVE_TO_COL')).with_changes('set MOVE_TO_COL "\\"echo -en \\033[${RES_COL}G\\""') }

    it 'maps a color name to its escape sequence, as in 3.x' do
      is_expected.to contain_augeas(setting('SETCOLOR_SUCCESS')).with_changes('set SETCOLOR_SUCCESS "\\"echo -en \\\\033[0;32m\\""')
    end

    it 'writes any other color verbatim' do
      is_expected.to contain_augeas(setting('SETCOLOR_FAILURE')).with_changes('set SETCOLOR_FAILURE "\\"echo -en \\033[0;41m\\""')
    end

    it { is_expected.to contain_augeas(setting('LOGLEVEL')).with_changes('set LOGLEVEL "3"') }
    it { is_expected.to contain_augeas(setting('PROMPT')).with_changes('set PROMPT "no"') }
    it { is_expected.to contain_augeas(setting('AUTOSWAP')).with_changes('set AUTOSWAP "yes"') }
    it { is_expected.not_to contain_augeas(setting('SETCOLOR_NORMAL')) }
    it { is_expected.not_to contain_augeas(setting('SINGLE')) }
    it { is_expected.to contain_augeas('/etc/sysconfig/init purge 0') }
    it { is_expected.to contain_file('/etc/sysconfig/init').with(mode: '0644').without_ensure }
  end

  context 'with a setting absent' do
    let(:params) { { prompt: 'absent' } }

    it { is_expected.to contain_augeas('/etc/sysconfig/init PROMPT').with_changes('rm PROMPT') }
  end

  context 'with single_user_login' do
    let(:params) { { single_user_login: '/sbin/sulogin' } }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_augeas('/etc/sysconfig/init SINGLE').with_changes('set SINGLE "/sbin/sulogin"') }

    ['emergency', 'rescue'].each do |unit|
      it { is_expected.to contain_file("/etc/systemd/system/#{unit}.service.d").with(ensure: 'directory', recurse: false, purge: false) }

      it do
        is_expected.to contain_file("/etc/systemd/system/#{unit}.service.d/#{unit}_exec.conf").with(
          mode: '0444',
          content: <<~CONF,
            [Service]
            ExecStart=
            ExecStart=-/bin/sh -c "/sbin/sulogin; /usr/bin/systemctl --fail --no-block default"
          CONF
        ).that_notifies('Exec[useradd systemctl daemon-reload]')
      end
    end

    it { is_expected.to contain_exec('useradd systemctl daemon-reload').with_refreshonly(true) }
  end

  context 'with single_user_login and purge_dropins' do
    let(:params) { { single_user_login: '/sbin/sulogin', purge_dropins: true } }

    it { is_expected.to contain_file('/etc/systemd/system/rescue.service.d').with(recurse: true, purge: true) }
  end

  context 'with single_user_login and systemd => true' do
    let(:params) { { single_user_login: '/sbin/sulogin', systemd: true } }

    it 'purges the drop-in directories as systemd does' do
      is_expected.to contain_file('/etc/systemd/system/rescue.service.d').with(recurse: true, purge: true)
    end
  end

  context 'with single_user_login, systemd => true and purge_dropins => false' do
    let(:params) { { single_user_login: '/sbin/sulogin', systemd: true, purge_dropins: false } }

    it { is_expected.to contain_file('/etc/systemd/system/rescue.service.d').with(recurse: false, purge: false) }
  end

  # Another module's systemd::dropin_file on the same unit declares the same
  # directory. Both must agree on its attributes.
  context 'with another drop-in on rescue.service' do
    let(:pre_condition) do
      <<~PP
        include systemd
        systemd::dropin_file { 'other.conf': unit => 'rescue.service', content => "[Service]\n" }
      PP
    end

    context 'and systemd => true' do
      let(:params) { { single_user_login: '/sbin/sulogin', systemd: true } }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_file('/etc/systemd/system/rescue.service.d/rescue_exec.conf') }
    end

    context 'and systemd::purge_dropin_dirs => false' do
      let(:pre_condition) do
        <<~PP
          class { 'systemd': purge_dropin_dirs => false }
          systemd::dropin_file { 'other.conf': unit => 'rescue.service', content => "[Service]\n" }
        PP
      end
      let(:params) { { single_user_login: '/sbin/sulogin', systemd: true } }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_file('/etc/systemd/system/rescue.service.d').with(purge: false) }
    end

    context 'and the defaults' do
      let(:params) { { single_user_login: '/sbin/sulogin' } }

      it { is_expected.to compile.and_raise_error(%r{Duplicate declaration: File\[/etc/systemd/system/rescue\.service\.d\]}) }
    end
  end

  context 'with single_user_login absent' do
    let(:params) { { single_user_login: 'absent' } }

    it { is_expected.to contain_file('/etc/systemd/system/rescue.service.d/rescue_exec.conf').with_ensure('absent') }
    it { is_expected.not_to contain_file('/etc/systemd/system/rescue.service.d') }
  end

  context 'without systemd' do
    let(:facts) { on_supported_os.first[1].merge(init_systems: ['sysv']) }
    let(:params) { { single_user_login: '/sbin/sulogin' } }

    it { expect(managing_resources).to be_empty }
  end

  context 'with systemd => true' do
    let(:params) { { systemd: true } }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('systemd') }
  end
end
