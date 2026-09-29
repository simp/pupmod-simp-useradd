require 'spec_helper'

describe 'useradd::libuser_conf' do
  let(:facts) { on_supported_os.first[1] }

  def augeas_resources
    catalogue.resources.select { |r| r.type == 'Augeas' }
  end

  context 'with default parameters' do
    it { is_expected.to compile.with_all_deps }
    it { expect(augeas_resources).to be_empty }
    it { is_expected.not_to contain_file('/etc/libuser.conf') }
  end

  context 'with settings' do
    let(:params) do
      {
        defaults_modules: ['files', 'shadow'],
        defaults_create_modules: ['ldap'],
        defaults_crypt_style: 'sha512',
        import_login_defs: '/etc/login.defs',
        files_nonroot: false,
        ldap_userbranch: 'ou=People',
        userdefaults_settings: { 'LU_USERNAME' => '%n', 'LU_GIDNUMBER' => '%u' },
      }
    end

    it { is_expected.to compile.with_all_deps }

    it 'edits one key per section in place' do
      is_expected.to contain_augeas('/etc/libuser.conf defaults/crypt_style').with(
        incl: '/etc/libuser.conf',
        lens: 'Puppet.lns',
        context: '/files/etc/libuser.conf',
        changes: 'set defaults/crypt_style "sha512"',
      )
    end

    it { is_expected.to contain_augeas('/etc/libuser.conf defaults/modules').with_changes('set defaults/modules "files,shadow"') }
    it { is_expected.to contain_augeas('/etc/libuser.conf defaults/create_modules').with_changes('set defaults/create_modules "ldap"') }
    it { is_expected.to contain_augeas('/etc/libuser.conf import/login_defs').with_changes('set import/login_defs "/etc/login.defs"') }
    # As in 3.x, a module's section is written only for a module in
    # create_modules and not in modules.
    it { is_expected.not_to contain_augeas('/etc/libuser.conf files/nonroot') }
    it { is_expected.to contain_augeas('/etc/libuser.conf ldap/userBranch').with_changes('set ldap/userBranch "ou=People"') }
    it { is_expected.to contain_augeas('/etc/libuser.conf userdefaults/LU_USERNAME').with_changes('set userdefaults/LU_USERNAME "%n"') }
    it { is_expected.to contain_augeas('/etc/libuser.conf userdefaults/LU_GIDNUMBER').with_changes('set userdefaults/LU_GIDNUMBER "%u"') }
    it { expect(augeas_resources.size).to eq(7) }
  end

  context 'with a section setting and only defaults_modules' do
    let(:params) { { defaults_modules: ['files', 'shadow'], files_nonroot: false } }

    it { is_expected.to contain_augeas('/etc/libuser.conf files/nonroot').with_changes('set files/nonroot "no"') }
  end

  context 'with a section key absent' do
    let(:params) { { userdefaults_settings: { 'LU_USERNAME' => '%n', 'LU_GIDNUMBER' => 'absent' } } }

    it { is_expected.to contain_augeas('/etc/libuser.conf userdefaults/LU_USERNAME').with_changes('set userdefaults/LU_USERNAME "%n"') }
    it { is_expected.to contain_augeas('/etc/libuser.conf userdefaults/LU_GIDNUMBER').with_changes('rm userdefaults/LU_GIDNUMBER') }
    it { is_expected.not_to contain_augeas('/etc/libuser.conf userdefaults') }
  end

  # The deprecated String is the whole section, as in 3.x.
  context 'with the deprecated userdefaults' do
    let(:params) do
      {
        userdefaults: "# a comment\nLU_USERNAME = %n\n\nLU_SHELL=/bin/sh\n",
        userdefaults_settings: { 'LU_GIDNUMBER' => '%u' },
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_augeas('/etc/libuser.conf userdefaults/LU_USERNAME').with_changes('set userdefaults/LU_USERNAME "%n"') }
    it { is_expected.to contain_augeas('/etc/libuser.conf userdefaults/LU_SHELL').with_changes('set userdefaults/LU_SHELL "/bin/sh"') }
    it { is_expected.not_to contain_augeas('/etc/libuser.conf userdefaults/LU_GIDNUMBER') }

    it 'removes the other keys in the section' do
      is_expected.to contain_augeas('/etc/libuser.conf userdefaults').with(
        changes: "rm userdefaults/*[label() != '#comment' and label() != 'LU_USERNAME' and label() != 'LU_SHELL']",
        onlyif: "match userdefaults/*[label() != '#comment' and label() != 'LU_USERNAME' and label() != 'LU_SHELL'] size > 0",
      )
    end

    context 'with strict=error' do
      before(:each) { Puppet[:strict] = :error }

      it { is_expected.to compile.with_all_deps }
    end
  end

  context 'with the deprecated userdefaults empty' do
    let(:params) { { userdefaults: '' } }

    it { is_expected.to contain_augeas('/etc/libuser.conf userdefaults').with_changes("rm userdefaults/*[label() != '#comment']") }
  end

  context 'with a free-form line that is not KEY = value' do
    let(:params) { { groupdefaults: 'LU_GROUPNAME %n' } }

    it { is_expected.to compile.and_raise_error(%r{groupdefaults: 'LU_GROUPNAME %n' is not a KEY = value line}) }
  end

  context 'with hash_rounds_min >= hash_rounds_max' do
    let(:params) { { defaults_hash_rounds_min: 5000, defaults_hash_rounds_max: 5000 } }

    it { is_expected.to compile.and_raise_error(%r{must be less than}) }
  end

  context 'with purge' do
    let(:params) do
      {
        defaults_crypt_style: 'sha512',
        import_login_defs: '/etc/login.defs',
        groupdefaults_settings: { 'LU_GROUPNAME' => '%n' },
        purge: true,
        mode: '0644',
      }
    end

    it 'purges unset keys in managed sections' do
      is_expected.to contain_augeas('/etc/libuser.conf purge 0').with_changes("rm import/*[label() != '#comment' and label() != 'login_defs']")
      is_expected.to contain_augeas('/etc/libuser.conf purge 1').with_changes("rm defaults/*[label() != '#comment' and label() != 'crypt_style']")
      is_expected.to contain_augeas('/etc/libuser.conf purge 2').with_changes("rm groupdefaults/*[label() != '#comment' and label() != 'LU_GROUPNAME']")
    end

    it 'purges every key in the other sections' do
      is_expected.to contain_augeas('/etc/libuser.conf purge 3').with_changes(
        "rm *[label() != 'import' and label() != 'defaults' and label() != 'groupdefaults']/*[label() != '#comment']",
      ).that_comes_before('File[/etc/libuser.conf]')
    end

    it { is_expected.to contain_file('/etc/libuser.conf').with_mode('0644').without_ensure }
  end
end
