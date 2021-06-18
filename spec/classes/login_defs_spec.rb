require 'spec_helper'

describe 'useradd::login_defs' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) do
          os_facts.merge( {
            :login_defs => { 'gid_min' => 1000, 'gid_max' => 500000 }
          } )
        end

        context 'with default parameters' do
          let(:expected) { File.read('spec/expected/default_login_defs') }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('useradd::login_defs') }
          it { is_expected.to create_file('/etc/login.defs').with_content(expected) }
        end

        context 'with everything defined or true' do
          let(:expected) { File.read('spec/expected/default_login_defs_all_true') }
          let(:params) {{
            :chfn_auth             => true,
            :chsh_auth             => true,
            :default_home          => true,
            :su_wheel_only         => true,
            :erasechar             => 100,
            :killchar              => 100,
            :max_members_per_group => 100,
            :pass_min_len          => 100,
            :sys_gid_max           => 100,
            :sys_gid_min           => 100,
            :gid_min               => 100,
            :gid_max               => 100,
            :sys_uid_max           => 100,
            :sys_uid_min           => 100,
            :uid_min               => 100,
            :uid_max               => 100,
            :ulimit                => 100,
            :env_hz                => 'HZ=100',
            :env_tz                => 'TZ=CST6CDT',
            :fake_shell            => '/usr/sbin/nologin',
            :ftmp_file             => '/tmp/ftmp',
            :hushlogin_file        => '/tmp/hushlogin',
            :login_string          => 'Password: ',
            :mail_file             => '/tmp/mailfile',
            :nologins_file         => '/tmp/nologins',
            :sulog_file            => '/tmp/sulog',
            :ttygroup              => 'puppet',
            :ttyperm               => '0600',
            :ttytype_file          => '/tmp/ttytype',
            :userdel_cmd           => '/usr/sbin/userdel',
            :console               => ['/dev/tty1'],
            :env_path              => ['/usr/bin','/usr/local/bin'],
            :env_supath            => ['/usr/bin','/usr/sbin/','/usr/local/bin'],
            :motd_file             => ['/etc/motd','/etc/issue']
          }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('useradd::login_defs') }
          it { is_expected.to create_file('/etc/login.defs').with_content(expected) }
        end

      end
    end
  end
end
