require 'spec_helper'

describe 'useradd::libuser_conf' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'with default parameters' do
          let(:expected) { File.read('spec/expected/default_libuser_conf') }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('useradd::libuser_conf') }
          it { is_expected.to create_file('/etc/libuser.conf').with_content(expected) }
        end

        context 'with everything enabled' do
          let(:expected) { File.read('spec/expected/default_libuser_conf_everything') }
          let(:params) {{
            :defaults_create_modules  => ['files','shadow','ldap'],
            :defaults_modules         => [],
            :defaults_hash_rounds_min => 1000,
            :defaults_hash_rounds_max => 9999,
            :defaults_mailspooldir    => '/var/mail',
            :defaults_moduledir       => '/usr/lib/libuser',
            :defaults_skeleton        => '/etc/skel',
            :files_directory          => '/etc',
            :files_nonroot            => true,
            :shadow_directory         => '/etc/shadow',
            :shadow_nonroot           => true,
            :ldap_userbranch          => 'ldapstuff1',
            :ldap_groupbranch         => 'ldapstuff2',
            :ldap_server              => 'ldapstuff3',
            :ldap_basedn              => 'ldapstuff4',
            :ldap_binddn              => 'ldapstuff5',
            :ldap_user                => 'ldapstuff6',
            :ldap_password            => 'ldapstuff7',
            :ldap_authuser            => 'ldapstuff8',
            :ldap_bindtype            => 'ldapstuff9',
            :sasl_appname             => 'saslstuff1',
            :sasl_domain              => 'saslstuff2'
          }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('useradd::libuser_conf') }
          it { is_expected.to create_file('/etc/libuser.conf').with_content(expected) }
        end

        context 'with incorrect hash_rounds' do
          let(:params){{
            :defaults_hash_rounds_min => 1001,
            :defaults_hash_rounds_max => 1000
          }}

          it {
            expect {
              is_expected.to compile.with_all_deps
            }.to raise_error(/must be less than/)
          }
        end
      end
    end
  end
end
