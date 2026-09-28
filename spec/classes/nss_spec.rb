require 'spec_helper'

describe 'useradd::nss' do
  let(:facts) { on_supported_os.first[1] }

  [{}, { netid_authoritative: true, services_authoritative: false, setent_batch_read: true }].each do |params|
    context "with #{params.empty? ? 'default parameters' : 'the deprecated parameters'}" do
      let(:params) { params }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.not_to contain_file('/etc/default/nss') }
    end
  end
end
