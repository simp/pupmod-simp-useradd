require 'spec_helper'

describe 'useradd::sysconfig_init' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/sysconfig/init').with_content(<<-EOF
# This file managed by Puppet.


BOOTUP=color
RES_COL=60
MOVE_TO_COL="echo -en \\\\033[${RES_COL}G"
SETCOLOR_SUCCESS="echo -en \\\\033[0;32m"
SETCOLOR_FAILURE="echo -en \\\\033[0;31m"
SETCOLOR_WARNING="echo -en \\\\033[0;33m"
SETCOLOR_NORMAL="echo -en \\\\033[0;39m"
SINGLE=/sbin/sulogin
LOGLEVEL=3
PROMPT=no
AUTOSWAP=no
            EOF
          )
        }

        if facts[:init_systems].include?('systemd')
          it { is_expected.to contain_systemd__dropin_file('emergency_exec.conf').with(
            {
              :unit    => 'emergency.service',
              :content => /ExecStart=.+sulogin/
            })
          }

          it { is_expected.to contain_systemd__dropin_file('rescue_exec.conf').with(
            {
              :unit    => 'rescue.service',
              :content => /ExecStart=.+sulogin/
            })
          }
        else
          it { is_expected.to_not contain_systemd__unit_file('emergency.service') }
          it { is_expected.to_not contain_systemd__unit_file('rescue.service') }
        end
      end
    end
  end
end
