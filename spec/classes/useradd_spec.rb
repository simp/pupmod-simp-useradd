require 'spec_helper'

describe 'useradd::useradd' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to create_file('/etc/default/useradd').with_content(<<-EOM.gsub(%r{^\s+}, ''))
               # This file managed by Puppet.
               # useradd defaults file
               GROUP=100
               HOME=/home
               INACTIVE=35
               SHELL=/bin/bash
               SKEL=/etc/skel
               CREATE_MAIL_SPOOL=yes
             EOM
        }

        context 'expire' do
          let(:params) { { expire: '2020-01-10' } }

          it {
            is_expected.to create_file('/etc/default/useradd').with_content(<<-EOM.gsub(%r{^\s+}, ''))
               # This file managed by Puppet.
               # useradd defaults file
               GROUP=100
               HOME=/home
               INACTIVE=35
               EXPIRE=2020-01-10
               SHELL=/bin/bash
               SKEL=/etc/skel
               CREATE_MAIL_SPOOL=yes
             EOM
          }
        end

        bad_expires = [
          '202-01-10',
          '111',
          '2020/01/10',
          'foo',
        ]

        bad_expires.each do |exp|
          context "bad_expire: #{exp}" do
            let(:params) { { expire: exp } }

            it {
              expect {
                is_expected.to compile
              }.to raise_error(%r{got '#{exp}'})
            }
          end
        end
      end
    end
  end
end
