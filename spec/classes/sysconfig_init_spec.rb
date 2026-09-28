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

  context 'with the deprecated display parameters' do
    let(:params) { { bootup: 'color', prompt: false } }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.not_to contain_file('/etc/sysconfig/init') }
  end

  context 'with single_user_login' do
    let(:params) { { single_user_login: '/sbin/sulogin' } }

    it { is_expected.to compile.with_all_deps }

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

  context 'with single_user_login and purge' do
    let(:params) { { single_user_login: '/sbin/sulogin', purge: true } }

    it { is_expected.to contain_file('/etc/systemd/system/rescue.service.d').with(recurse: true, purge: true) }
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
