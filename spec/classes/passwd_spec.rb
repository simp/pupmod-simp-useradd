require 'spec_helper'

describe 'useradd::passwd' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      let(:facts){ os_facts }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to create_class('useradd::passwd') }
      it {
        expected_params = {
          :owner => 'root',
          :group => 'root',
          :mode  => '0644'
        }
        is_expected.to create_file('/etc/passwd').with(expected_params)
        is_expected.to create_file('/etc/passwd-').with(expected_params)
        is_expected.to create_file('/etc/group').with(expected_params)
        is_expected.to create_file('/etc/group-').with(expected_params)
      }
      it {
        expected_params = {
          :owner => 'root',
          :group => 'root',
          :mode  => '0000'
        }
        is_expected.to create_file('/etc/shadow').with(expected_params)
        is_expected.to create_file('/etc/shadow-').with(expected_params)
        is_expected.to create_file('/etc/gshadow').with(expected_params)
        is_expected.to create_file('/etc/gshadow-').with(expected_params)
      }

    end
  end
end
