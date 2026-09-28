require 'spec_helper'

describe 'useradd_legacy_simp_sh' do
  before(:each) do
    Facter.clear
    allow(Facter.fact(:kernel)).to receive(:value).and_return('Linux')
    allow(File).to receive(:exist?).and_call_original
  end

  [
    [false, false, false],
    [true, false, true],
    [false, true, true],
  ].each do |sh, csh, expected|
    it "is #{expected} with simp.sh #{sh ? 'present' : 'missing'} and simp.csh #{csh ? 'present' : 'missing'}" do
      allow(File).to receive(:exist?).with('/etc/profile.d/simp.sh').and_return(sh)
      allow(File).to receive(:exist?).with('/etc/profile.d/simp.csh').and_return(csh)
      expect(Facter.fact(:useradd_legacy_simp_sh).value).to eq(expected)
    end
  end
end
