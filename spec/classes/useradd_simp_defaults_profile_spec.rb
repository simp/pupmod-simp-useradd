# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

# Tests the `simp:defaults` compliance profile end to end: with
# `compliance_engine::enforcement: [simp:defaults]` in Hiera, the otherwise
# no-op `include useradd` must reproduce what useradd 3.x managed by default.
#
# The "bare include manages nothing" specs live in init_spec.rb.
describe 'useradd' do
  def self.profile_dir
    File.expand_path('../../SIMP/compliance_profiles', __dir__)
  end

  def self.checks
    YAML.safe_load_file(File.join(profile_dir, 'checks.yaml'))['checks']
  end

  let(:hiera_config) do
    File.expand_path('../fixtures/hieradata/hiera_compliance_engine.yaml', __dir__)
  end

  # ---------------------------------------------------------------------------
  # Profile/check data integrity. No catalogue compilation.
  # ---------------------------------------------------------------------------
  context 'profile data' do
    let(:checks) { self.class.checks }
    let(:profile) { YAML.safe_load_file(File.join(self.class.profile_dir, 'profile-simp_defaults.yaml'))['profiles']['simp:defaults'] }

    it 'lists exactly the defined checks (no orphans, none missing)' do
      expect(profile['checks'].keys.sort).to eq(checks.keys.sort)
    end

    it 'names every check after its parameter' do
      mismatched = checks.reject do |id, check|
        id == "simp:defaults.#{check['settings']['parameter'].tr(':', '.').squeeze('.')}"
      end
      expect(mismatched.keys).to be_empty
    end

    # A check naming a parameter that does not exist binds nothing and fails
    # silently.
    it 'names only parameters the useradd classes actually declare' do
      missing = checks.values.map { |c| c['settings']['parameter'] }.reject do |param|
        klass, _, name = param.rpartition('::')
        manifest = (klass == 'useradd') ? 'init' : klass.delete_prefix('useradd::')
        src = File.read(File.expand_path("../../manifests/#{manifest}.pp", __dir__))
        src.match?(%r{^\s+\S.*\$#{Regexp.escape(name)}\s+=})
      end
      expect(missing).to be_empty
    end

    # The deprecated parameters must not be how the profile restores 3.x.
    it 'sets no deprecated parameter' do
      deprecated = %r{::(manage_\w+|securetty|shells|shells_default|userdefaults|groupdefaults)\z}
      params = checks.values.map { |c| c['settings']['parameter'] }
      expect(params.grep(deprecated)).to be_empty
    end

    # simp_options::uid/gid still feed these; a literal would override sites.
    it 'leaves the UID/GID ranges to simp_options' do
      params = checks.values.map { |c| c['settings']['parameter'] }
      expect(params.grep(%r{::(uid|gid)_(min|max)\z})).to be_empty
    end
  end

  # ---------------------------------------------------------------------------
  # Enforced, no overrides: reproduces the 3.x catalogue.
  # ---------------------------------------------------------------------------
  context 'when enforcing simp:defaults' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts.merge(custom_hiera: 'simp_defaults_enforced', init_systems: ['systemd']) }

        it { is_expected.to compile.with_all_deps }

        checks.each_value do |check|
          it "sets #{check['settings']['parameter']}" do
            klass, _, name = check['settings']['parameter'].rpartition('::')
            is_expected.to contain_class(klass).with(name => check['settings']['value'])
          end
        end

        it 'restores the securetty entries, purge and mode' do
          ['tty0', 'tty1', 'tty2', 'tty3', 'tty4'].each do |tty|
            is_expected.to contain_augeas("/etc/securetty #{tty}").with_changes("set 01[last()+1] #{tty}")
          end
          is_expected.to contain_augeas('/etc/securetty purge')
          is_expected.to contain_file('/etc/securetty').with_mode('0400')
        end

        it 'restores the shells and purges the rest' do
          is_expected.to contain_augeas('/etc/shells /bin/bash')
          is_expected.to contain_augeas('/etc/shells purge')
          is_expected.to contain_file('/etc/shells').with(owner: 'root', group: 'root', mode: '0644')
        end

        it 'restores login.defs' do
          is_expected.to contain_augeas('/etc/login.defs PASS_MAX_DAYS')
          is_expected.to contain_augeas('/etc/login.defs purge 0')
          is_expected.to contain_file('/etc/login.defs').with_mode('0640')
        end

        it 'restores /etc/default/useradd' do
          is_expected.to contain_augeas('/etc/default/useradd INACTIVE').with_changes(['rm INACTIVE[position() > 1]', 'set INACTIVE "35"'])
          is_expected.to contain_file('/etc/default/useradd').with_mode('0600')
        end

        it 'restores libuser.conf' do
          is_expected.to contain_augeas('/etc/libuser.conf defaults/crypt_style').with_changes(['rm defaults/crypt_style[position() > 1]', 'set defaults/crypt_style "sha512"'])
          is_expected.to contain_augeas('/etc/libuser.conf userdefaults/LU_USERNAME').with_changes(['rm userdefaults/LU_USERNAME[position() > 1]', 'set userdefaults/LU_USERNAME "%n"'])
          is_expected.to contain_file('/etc/libuser.conf').with_mode('0644')
        end

        it 'restores the passwd file permissions' do
          is_expected.to contain_file('/etc/shadow').with(owner: 'root', group: 'root', mode: '0000')
          is_expected.to contain_file('/etc/passwd').with(owner: 'root', group: 'root', mode: '0644')
        end

        it 'writes the login settings and removes the 3.x scripts' do
          is_expected.to contain_file('/etc/profile.d/simp-b-tmout.sh').with_content(%r{TMOUT=900})
          is_expected.to contain_file('/etc/profile.d/zz-simp-autologout.csh').with_content(%r{autologout=15})
          is_expected.to contain_file('/etc/profile.d/zz-simp-umask.sh').with_content(%r{umask 0077})
          is_expected.to contain_file('/etc/profile.d/zz-simp-mesg.sh').with_content(%r{mesg n})
          is_expected.to contain_file('/etc/profile.d/simp.sh').with_ensure('absent')
          is_expected.to contain_file('/etc/profile.d/simp.csh').with_ensure('absent')
        end

        it 'restores the single-user login drop-ins' do
          is_expected.to contain_file('/etc/systemd/system/rescue.service.d/rescue_exec.conf').with_content(%r{/sbin/sulogin})
          is_expected.to contain_class('systemd')
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Backend wired up but enforcing nothing.
  # ---------------------------------------------------------------------------
  context 'without enforcement' do
    let(:facts) { on_supported_os.first[1].merge(custom_hiera: 'simp_defaults_disabled', init_systems: ['systemd']) }

    it { is_expected.to compile.with_all_deps }

    it 'manages nothing' do
      expect(catalogue.resources.select { |r| ['File', 'Augeas', 'Exec'].include?(r.type) }.map(&:ref)).to eq([])
    end
  end

  # ---------------------------------------------------------------------------
  # Enforced + explicit site values. The site sits above the compliance engine
  # in the hierarchy, so it must win; Hash parameters deep-merge.
  # ---------------------------------------------------------------------------
  context 'when explicit Hiera values override the profile' do
    let(:facts) { on_supported_os.first[1].merge(custom_hiera: 'simp_defaults_with_override', init_systems: ['systemd']) }

    it { is_expected.to compile.with_all_deps }

    it 'uses the site pass_max_days' do
      is_expected.to contain_augeas('/etc/login.defs PASS_MAX_DAYS').with_changes(['rm PASS_MAX_DAYS[position() > 1]', 'set PASS_MAX_DAYS "60"'])
    end

    it 'merges the site securetty entries with the profile' do
      is_expected.to contain_augeas('/etc/securetty console').with_changes('set 01[last()+1] console')
      is_expected.to contain_augeas('/etc/securetty tty1').with_changes('set 01[last()+1] tty1')
      is_expected.to contain_augeas('/etc/securetty tty4').with_changes(%r{\Arm })
    end

    it 'lets the site turn off a destructive toggle' do
      is_expected.to contain_class('useradd').with_purge_shells(false)
      is_expected.not_to contain_augeas('/etc/shells purge')
      is_expected.to contain_augeas('/etc/shells /bin/bash')
    end

    it 'merges the site libuser.conf keys with the profile' do
      is_expected.to contain_augeas('/etc/libuser.conf userdefaults/LU_USERNAME').with_changes(['rm userdefaults/LU_USERNAME[position() > 1]', 'set userdefaults/LU_USERNAME "%n"'])
      is_expected.to contain_augeas('/etc/libuser.conf userdefaults/LU_GIDNUMBER').with_changes('rm userdefaults/LU_GIDNUMBER')
    end

    it 'leaves the rest of the profile in force' do
      is_expected.to contain_augeas('/etc/login.defs PASS_MIN_DAYS')
      is_expected.to contain_augeas('/etc/securetty purge')
    end
  end

  # ---------------------------------------------------------------------------
  # Enforced + the deprecated 3.x parameters, which keep their 3.x behavior.
  # ---------------------------------------------------------------------------
  context 'when the site still sets the deprecated parameters' do
    let(:facts) { on_supported_os.first[1].merge(custom_hiera: 'simp_defaults_with_legacy', init_systems: ['systemd']) }

    it { is_expected.to compile.with_all_deps }

    it 'owns /etc/securetty as in 3.x' do
      is_expected.to contain_file('/etc/securetty').with(ensure: 'file', mode: '0400', content: '')
      expect(catalogue.resources.select { |r| r.type == 'Augeas' && r.title.start_with?('/etc/securetty') }).to be_empty
    end

    it 'leaves /etc/shells alone' do
      is_expected.not_to contain_file('/etc/shells')
      expect(catalogue.resources.select { |r| r.type == 'Augeas' && r.title.start_with?('/etc/shells') }).to be_empty
    end

    it 'owns the [userdefaults] section as in 3.x' do
      is_expected.to contain_augeas('/etc/libuser.conf userdefaults/LU_USERNAME')
      is_expected.not_to contain_augeas('/etc/libuser.conf userdefaults/LU_GIDNUMBER')
      is_expected.to contain_augeas('/etc/libuser.conf userdefaults').with_changes("rm userdefaults/*[label() != '#comment' and label() != 'LU_USERNAME']")
    end

    it 'writes prepend to its own script' do
      is_expected.to contain_file('/etc/profile.d/simp-a-prepend.sh').with_content(%r{^echo pre$})
    end

    it 'leaves the rest of the profile in force' do
      is_expected.to contain_augeas('/etc/login.defs PASS_MAX_DAYS')
    end
  end
end
