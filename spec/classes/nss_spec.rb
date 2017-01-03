require 'spec_helper'

describe 'useradd::nss' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('useradd::nss') }
          it { is_expected.to create_file('/etc/default/nss').with_content(<<-'EOM'.gsub(/^\s+/,''))
             NETID_AUTHORITATIVE=FALSE
             SERVICES_AUTHORITATIVE=FALSE
             SETENT_BATCH_READ=TRUE
           EOM
          }
        end

      end
    end
  end
end
