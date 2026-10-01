require 'spec_helper'

describe 'useradd::passwd' do
  let(:facts) { on_supported_os.first[1] }

  context 'with default parameters' do
    it { is_expected.to compile.with_all_deps }
    it { expect(catalogue.resources.select { |r| r.type == 'File' }).to be_empty }
  end

  context 'with files' do
    let(:params) do
      {
        files: {
          '/etc/passwd' => { 'owner' => 'root', 'group' => 'root', 'mode' => '0644' },
          '/etc/shadow' => { 'mode' => '0000' },
        }
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_file('/etc/passwd').with(owner: 'root', group: 'root', mode: '0644').without_ensure }
    it { is_expected.to contain_file('/etc/shadow').with_mode('0000').without_owner.without_group.without_ensure }
  end
end
