require 'spec_helper'

describe 'useradd' do
  # Every resource type the module can declare to change a node.
  MANAGING_TYPES = ['File', 'Augeas', 'Exec'].freeze

  def managing_resources
    catalogue.resources.select { |r| MANAGING_TYPES.include?(r.type) }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }

        ['etc_profile', 'libuser_conf', 'login_defs', 'nss', 'passwd', 'sysconfig_init', 'useradd'].each do |klass|
          it { is_expected.to contain_class("useradd::#{klass}") }
        end

        it 'manages nothing' do
          expect(managing_resources.map(&:ref)).to eq([])
        end
      end
    end
  end

  context 'with parameters' do
    let(:facts) { on_supported_os.first[1] }

    context 'with securetty_entries' do
      let(:params) { { securetty_entries: { 'tty1' => {}, 'tty9' => { 'ensure' => 'absent' } } } }

      it { is_expected.to compile.with_all_deps }

      it 'adds a present entry in place' do
        is_expected.to contain_augeas('/etc/securetty tty1').with(
          incl: '/etc/securetty',
          lens: 'Securetty.lns',
          context: '/files/etc/securetty',
          changes: 'set 01[last()+1] tty1',
          onlyif: "match *[label() != '#comment' and . = 'tty1'] size == 0",
        )
      end

      it 'removes an absent entry' do
        is_expected.to contain_augeas('/etc/securetty tty9').with(
          changes: "rm *[label() != '#comment' and . = 'tty9']",
          onlyif: "match *[label() != '#comment' and . = 'tty9'] size > 0",
        )
      end

      it { is_expected.not_to contain_augeas('/etc/securetty purge') }
      it { is_expected.not_to contain_file('/etc/securetty') }
    end

    context 'with purge_securetty' do
      let(:params) { { securetty_entries: { 'tty1' => {}, 'tty9' => { 'ensure' => 'absent' } }, purge_securetty: true } }

      it 'removes every entry that is not present' do
        is_expected.to contain_augeas('/etc/securetty purge').with_changes(
          "rm *[label() != '#comment' and . != 'tty1']",
        )
      end
    end

    context 'with purge_securetty and no present entry' do
      let(:params) { { securetty_entries: { 'tty9' => { 'ensure' => 'absent' } }, purge_securetty: true } }

      it { is_expected.not_to contain_augeas('/etc/securetty purge') }
    end

    context 'with securetty_mode' do
      let(:params) { { securetty_entries: { 'tty1' => {} }, securetty_mode: '0400' } }

      it 'sets the mode without creating the file' do
        is_expected.to contain_file('/etc/securetty').with(owner: 'root', group: 'root', mode: '0400').without_ensure
      end

      it { is_expected.to contain_augeas('/etc/securetty tty1').that_comes_before('File[/etc/securetty]') }
    end

    context 'with the deprecated securetty Array' do
      let(:params) { { securetty_entries: { 'tty1' => {} }, purge_securetty: true, securetty: ['console', 'tty+x'] } }

      it 'owns the whole file, as in 3.x' do
        is_expected.to contain_file('/etc/securetty').with(ensure: 'file', owner: 'root', group: 'root', mode: '0400', content: "console\ntty+x")
      end

      it 'ignores securetty_entries and purge_securetty' do
        expect(catalogue.resources.select { |r| r.type == 'Augeas' }).to be_empty
      end
    end

    context 'with the deprecated securetty Array and securetty_mode' do
      let(:params) { { securetty: ['console'], securetty_mode: '0600' } }

      it { is_expected.to contain_file('/etc/securetty').with_mode('0600') }
    end

    context 'with an entry option that does not exist' do
      let(:params) { { securetty_entries: { 'tty1' => { 'ensrue' => 'absent' } } } }

      it { is_expected.to compile.and_raise_error(%r{unrecognized key 'ensrue'}) }
    end

    context 'with securetty containing ANY_SHELL' do
      let(:params) { { securetty: ['console', 'ANY_SHELL'] } }

      it { is_expected.to contain_file('/etc/securetty').with_ensure('absent') }
      it { is_expected.not_to contain_augeas('/etc/securetty console') }
    end

    [true, []].each do |value|
      context "with securetty => #{value.inspect}" do
        let(:params) { { securetty: value } }

        it 'leaves an empty file' do
          is_expected.to contain_file('/etc/securetty').with(ensure: 'file', mode: '0400', content: '')
        end
      end
    end

    context 'with securetty => false' do
      let(:params) { { securetty: false, securetty_entries: { 'tty1' => {} }, purge_securetty: true, securetty_mode: '0400' } }

      it { expect(managing_resources).to be_empty }
    end

    context 'with shells_entries and purge_shells' do
      let(:params) { { shells_entries: { '/bin/bash' => {}, '/bin/csh' => { 'ensure' => 'absent' } }, purge_shells: true } }

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_augeas('/etc/shells /bin/bash').with(
          incl: '/etc/shells',
          lens: 'Shells.lns',
          changes: 'set 01[last()+1] /bin/bash',
        )
      end

      it { is_expected.to contain_augeas('/etc/shells /bin/csh').with_changes(%r{\Arm }) }
      it { is_expected.to contain_augeas('/etc/shells purge').with_changes("rm *[label() != '#comment' and . != '/bin/bash']") }
      it { is_expected.not_to contain_file('/etc/shells') }
    end

    context 'with the deprecated shells_default and shells Arrays' do
      let(:params) { { shells_entries: { '/bin/ksh' => {} }, purge_shells: true, shells_default: ['/bin/sh', '/bin/zsh'], shells: ['/usr/bin/c++sh'] } }

      it 'owns the whole file, as in 3.x' do
        is_expected.to contain_file('/etc/shells').with(owner: 'root', group: 'root', mode: '0644', content: "/bin/sh\n/bin/zsh\n/usr/bin/c++sh").without_ensure
      end

      it 'ignores shells_entries and purge_shells' do
        expect(catalogue.resources.select { |r| r.type == 'Augeas' }).to be_empty
      end
    end

    context 'with only the deprecated shells Array' do
      let(:params) { { shells: ['/bin/foo'] } }

      it 'lists the 3.x shells_default first' do
        is_expected.to contain_file('/etc/shells').with_content(
          "/bin/sh\n/bin/bash\n/sbin/nologin\n/usr/bin/sh\n/usr/bin/bash\n/usr/sbin/nologin\n/bin/foo",
        )
      end
    end

    context 'with shells_mode' do
      let(:params) { { shells_entries: { '/bin/bash' => {} }, purge_shells: true, shells_mode: '0444' } }

      it 'sets the mode without creating the file' do
        is_expected.to contain_file('/etc/shells').with(owner: 'root', group: 'root', mode: '0444').without_ensure
      end

      it { is_expected.to contain_augeas('/etc/shells /bin/bash').that_comes_before('File[/etc/shells]') }
      it { is_expected.to contain_augeas('/etc/shells purge').that_comes_before('File[/etc/shells]') }
    end

    context 'with shells => false' do
      let(:params) { { shells_default: ['/bin/sh'], shells: false, shells_entries: { '/bin/sh' => {} }, purge_shells: true, shells_mode: '0644' } }

      it { expect(managing_resources).to be_empty }
    end

    context 'with an entry holding a quote' do
      let(:params) { { shells_entries: { "/bin/a'b" => {} } } }

      it { is_expected.to compile.and_raise_error(%r{expects a match for Useradd::ListEntry}) }
    end

    context 'with manage_login_defs => false' do
      let(:params) { { manage_login_defs: false } }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.not_to contain_class('useradd::login_defs') }
      it { is_expected.to contain_class('useradd::useradd') }
    end

    context 'with manage_passwd_perms => true' do
      let(:params) { { manage_passwd_perms: true } }

      it 'still includes the class, which manages nothing unset' do
        is_expected.to contain_class('useradd::passwd')
        expect(managing_resources).to be_empty
      end
    end
  end

  # Deprecations must warn without failing compilation.
  context 'with every deprecated parameter and strict=error' do
    let(:facts) { on_supported_os.first[1] }
    let(:params) do
      {
        securetty: ['tty1'], shells_default: ['/bin/sh'], shells: ['/bin/bash'],
        manage_etc_profile: true, manage_libuser_conf: true, manage_login_defs: true, manage_nss: true,
        manage_passwd_perms: true, manage_sysconfig_init: true, manage_useradd: true
      }
    end

    before(:each) { Puppet[:strict] = :error }

    it { is_expected.to compile.with_all_deps }
  end
end
