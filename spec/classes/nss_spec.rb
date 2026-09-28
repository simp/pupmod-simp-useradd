require 'spec_helper'

describe 'useradd::nss' do
  let(:facts) { on_supported_os.first[1] }

  context 'with default parameters' do
    it { is_expected.to compile.with_all_deps }
    it { expect(catalogue.resources.select { |r| ['File', 'Augeas'].include?(r.type) }).to be_empty }
  end

  context 'with every setting' do
    let(:params) { { netid_authoritative: true, services_authoritative: false, setent_batch_read: 'absent', mode: '0640', purge: true } }

    it { is_expected.to compile.with_all_deps }

    it do
      is_expected.to contain_augeas('/etc/default/nss NETID_AUTHORITATIVE').with(
        incl: '/etc/default/nss',
        lens: 'Shellvars.lns',
        changes: 'set NETID_AUTHORITATIVE "TRUE"',
      )
    end

    it { is_expected.to contain_augeas('/etc/default/nss SERVICES_AUTHORITATIVE').with_changes('set SERVICES_AUTHORITATIVE "FALSE"') }
    it { is_expected.to contain_augeas('/etc/default/nss SETENT_BATCH_READ').with_changes('rm SETENT_BATCH_READ') }
    it { is_expected.to contain_augeas('/etc/default/nss purge 0') }
    it { is_expected.to contain_file('/etc/default/nss').with(owner: 'root', group: 'root', mode: '0640').without_ensure }
  end
end
