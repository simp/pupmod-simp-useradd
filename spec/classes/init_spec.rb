require 'spec_helper'

describe 'useradd' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('useradd') }

        it { is_expected.to create_file('/etc/securetty').with_content(<<-EOF.gsub(/^\s+/,'').strip
        EOF
        ) }

        it { is_expected.to create_file('/etc/shells').with_content(<<-EOF.gsub(/^\s+/,'').strip
          /bin/sh
          /bin/bash
          /sbin/nologin
          /usr/bin/sh
          /usr/bin/bash
          /usr/sbin/nologin
        EOF
        ) }

        context 'when adding a securetty entry' do
          let(:params){{
            :securetty => ['console']
          }}

          it { is_expected.to create_file('/etc/securetty').with_content(<<-EOF.gsub(/^\s+/,'').strip
            console
          EOF
          ) }
        end

        context 'when allowing from ANY_SHELL' do
          let(:params){{
            :securetty => ['console', 'ANY_SHELL']
          }}

          it { is_expected.to create_file('/etc/securetty').with_ensure('absent') }
        end

        context 'when adding a shell' do
          let(:params){{
            :shells => ['/bin/foo']
          }}

          it { is_expected.to create_file('/etc/shells').with_content(<<-EOF.gsub(/^\s+/,'').strip
            /bin/sh
            /bin/bash
            /sbin/nologin
            /usr/bin/sh
            /usr/bin/bash
            /usr/sbin/nologin
            /bin/foo
          EOF
          ) }
        end

        context 'with shells => false' do
          let(:params) {{ :shells => false }}
          it { is_expected.not_to create_file('/etc/shells') }
        end

        context 'with securetty => false' do
          let(:params) {{ :securetty => false }}
          it { is_expected.not_to create_file('/etc/securetty') }
        end
      end
    end
  end
end
