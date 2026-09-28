require 'spec_helper'

describe 'useradd::useradd' do
  let(:facts) { on_supported_os.first[1] }

  def augeas_resources
    catalogue.resources.select { |r| r.type == 'Augeas' }
  end

  context 'with default parameters' do
    it { is_expected.to compile.with_all_deps }
    it { expect(augeas_resources).to be_empty }
    it { is_expected.not_to contain_file('/etc/default/useradd') }
  end

  context 'with settings' do
    let(:params) { { inactive: 35, shell: '/bin/bash', create_mail_spool: true, expire: 'absent' } }

    it { is_expected.to compile.with_all_deps }

    it do
      is_expected.to contain_augeas('/etc/default/useradd INACTIVE').with(
        incl: '/etc/default/useradd',
        lens: 'Shellvars.lns',
        context: '/files/etc/default/useradd',
        changes: 'set INACTIVE "35"',
      )
    end

    it { is_expected.to contain_augeas('/etc/default/useradd SHELL').with_changes('set SHELL "/bin/bash"') }
    it { is_expected.to contain_augeas('/etc/default/useradd CREATE_MAIL_SPOOL').with_changes('set CREATE_MAIL_SPOOL "yes"') }
    it { is_expected.to contain_augeas('/etc/default/useradd EXPIRE').with_changes('rm EXPIRE') }
    it { expect(augeas_resources.size).to eq(4) }
  end

  context 'with purge and mode' do
    let(:params) { { inactive: 35, expire: 'absent', purge: true, mode: '0600' } }

    it do
      is_expected.to contain_augeas('/etc/default/useradd purge 0').with_changes(
        "rm *[label() != '#comment' and label() != 'INACTIVE']",
      ).that_comes_before('File[/etc/default/useradd]')
    end

    it { is_expected.to contain_file('/etc/default/useradd').with_mode('0600').without_ensure }
  end
end
