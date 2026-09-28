require 'spec_helper'

describe 'useradd::login_defs' do
  let(:facts) { on_supported_os.first[1] }

  def augeas_resources
    catalogue.resources.select { |r| r.type == 'Augeas' }
  end

  context 'with default parameters' do
    it { is_expected.to compile.with_all_deps }
    it { expect(augeas_resources).to be_empty }
    it { is_expected.not_to contain_file('/etc/login.defs') }
  end

  context 'with settings' do
    let(:params) do
      {
        pass_max_days: 90,
        umask: '077',
        create_home: true,
        faillog_enab: false,
        console: ['/dev/tty1', '/dev/tty2'],
        console_groups: ['floppy', 'audio'],
        env_tz: 'America/New_York',
        env_hz: '100',
        login_string: 'Password for "%s": ',
      }
    end

    it { is_expected.to compile.with_all_deps }

    it 'edits one key per parameter in place' do
      is_expected.to contain_augeas('/etc/login.defs PASS_MAX_DAYS').with(
        incl: '/etc/login.defs',
        lens: 'Login_defs.lns',
        context: '/files/etc/login.defs',
        changes: 'set PASS_MAX_DAYS "90"',
      )
    end

    it { is_expected.to contain_augeas('/etc/login.defs UMASK').with_changes('set UMASK "077"') }
    it { is_expected.to contain_augeas('/etc/login.defs CREATE_HOME').with_changes('set CREATE_HOME "yes"') }
    it { is_expected.to contain_augeas('/etc/login.defs FAILLOG_ENAB').with_changes('set FAILLOG_ENAB "no"') }
    it { is_expected.to contain_augeas('/etc/login.defs CONSOLE').with_changes('set CONSOLE "/dev/tty1:/dev/tty2"') }
    it { is_expected.to contain_augeas('/etc/login.defs CONSOLE_GROUPS').with_changes('set CONSOLE_GROUPS "floppy,audio"') }
    it { is_expected.to contain_augeas('/etc/login.defs ENV_TZ').with_changes('set ENV_TZ "TZ=America/New_York"') }
    it { is_expected.to contain_augeas('/etc/login.defs ENV_HZ').with_changes('set ENV_HZ "HZ=100"') }
    it { is_expected.to contain_augeas('/etc/login.defs LOGIN_STRING').with_changes('set LOGIN_STRING "Password for \"%s\": "') }

    it 'leaves every other key alone' do
      expect(augeas_resources.size).to eq(params.size)
    end

    it { is_expected.not_to contain_augeas('/etc/login.defs purge 0') }
  end

  context 'with a backslash in a value' do
    let(:params) { { login_string: 'a\\b' } }

    # The augeas provider passes `\x` through verbatim.
    it { is_expected.to contain_augeas('/etc/login.defs LOGIN_STRING').with_changes('set LOGIN_STRING "a\\b"') }
  end

  ['a\\', 'a\\"b'].each do |value|
    context "with the value #{value.inspect}" do
      let(:params) { { login_string: value } }

      it { is_expected.to compile.and_raise_error(%r{backslash before a double quote or at the end}) }
    end
  end

  # 3.x accepted '', but the Login_defs lens can't parse a key with no value.
  context 'with an empty string' do
    let(:params) { { login_string: '', umask: '', console_groups: ['', 'floppy'] } }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.not_to contain_augeas('/etc/login.defs LOGIN_STRING') }
    it { is_expected.not_to contain_augeas('/etc/login.defs UMASK') }
    it { is_expected.to contain_augeas('/etc/login.defs CONSOLE_GROUPS').with_changes('set CONSOLE_GROUPS "floppy"') }

    context 'with strict=error' do
      before(:each) { Puppet[:strict] = :error }

      it { is_expected.to compile.with_all_deps }
    end
  end

  context 'with a setting absent' do
    let(:params) { { pass_max_days: 'absent' } }

    it do
      is_expected.to contain_augeas('/etc/login.defs PASS_MAX_DAYS').with(
        changes: 'rm PASS_MAX_DAYS',
        onlyif: 'match PASS_MAX_DAYS size > 0',
      )
    end
  end

  context 'with the UID/GID ranges from simp_options' do
    let(:facts) { on_supported_os.first[1].merge(custom_hiera: 'simp_options_uid_gid') }

    it { is_expected.to contain_augeas('/etc/login.defs UID_MIN').with_changes('set UID_MIN "1000"') }
    it { is_expected.to contain_augeas('/etc/login.defs GID_MAX').with_changes('set GID_MAX "600000"') }
  end

  context 'with purge' do
    let(:params) { { pass_max_days: 90, umask: 'absent', purge: true } }

    it 'keeps the set keys and the UID/GID ranges' do
      is_expected.to contain_augeas('/etc/login.defs purge 0').with_changes(
        "rm *[label() != '#comment' and label() != 'PASS_MAX_DAYS' and label() != 'UID_MIN' and label() != 'UID_MAX' and label() != 'GID_MIN' and label() != 'GID_MAX']",
      )
    end
  end

  context 'with purge and nothing set' do
    let(:params) { { purge: true } }

    it { expect(augeas_resources).to be_empty }
  end

  context 'with mode' do
    let(:params) { { pass_max_days: 90, mode: '0640' } }

    it 'sets the mode without creating the file' do
      is_expected.to contain_file('/etc/login.defs').with(owner: 'root', group: 'root', mode: '0640').without_ensure
    end

    it { is_expected.to contain_augeas('/etc/login.defs PASS_MAX_DAYS').that_comes_before('File[/etc/login.defs]') }
  end
end
