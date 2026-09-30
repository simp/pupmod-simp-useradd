require 'spec_helper'

describe 'useradd::etc_profile' do
  let(:facts) { on_supported_os.first[1] }

  HEADER = "# This file managed by Puppet - DO NOT EDIT\n# Any changes will be overwritten at the next run.\n\n".freeze

  context 'with default parameters' do
    it { is_expected.to compile.with_all_deps }
    it { expect(catalogue.resources.select { |r| r.type == 'File' }).to be_empty }
  end

  context 'with every setting' do
    let(:params) { { session_timeout: 15, mesg: false, umask: '0077' } }

    it { is_expected.to compile.with_all_deps }

    it 'writes one file per setting' do
      is_expected.to contain_file('/etc/profile.d/simp-b-tmout.sh').with(
        ensure: 'file',
        owner: 'root',
        group: 'root',
        mode: '0644',
        seltype: 'bin_t',
        content: "#{HEADER}[ $TMOUT ] || export TMOUT=900\nreadonly TMOUT\n",
      )
    end

    it { is_expected.to contain_file('/etc/profile.d/zz-simp-autologout.csh').with_content("#{HEADER}set autologout=15\n") }
    it { is_expected.to contain_file('/etc/profile.d/zz-simp-mesg.sh').with_content("#{HEADER}if tty -s; then\n  mesg n\nfi\n") }
    it { is_expected.to contain_file('/etc/profile.d/zz-simp-mesg.csh').with_content("#{HEADER}tty -s\nif ( $? == 0 ) mesg n\n") }
    it { is_expected.to contain_file('/etc/profile.d/zz-simp-umask.sh').with_content("#{HEADER}umask 0077\n") }
    it { is_expected.to contain_file('/etc/profile.d/zz-simp-umask.csh').with_content("#{HEADER}umask 0077\n") }
    it { is_expected.not_to contain_file('/etc/profile.d/simp.sh') }
  end

  context 'with a setting absent' do
    let(:params) { { session_timeout: 'absent', mesg: 'absent', umask: 'absent' } }

    [
      'simp-b-tmout.sh', 'zz-simp-autologout.csh', 'zz-simp-mesg.sh',
      'zz-simp-mesg.csh', 'zz-simp-umask.sh', 'zz-simp-umask.csh'
    ].each do |name|
      it { is_expected.to contain_file("/etc/profile.d/#{name}").with_ensure('absent') }
    end
  end

  context 'with manage_tmout => false' do
    let(:params) { { session_timeout: 15, manage_tmout: false } }

    it { is_expected.not_to contain_file('/etc/profile.d/simp-b-tmout.sh') }
    it { is_expected.not_to contain_file('/etc/profile.d/zz-simp-autologout.csh') }
  end

  context 'with user_whitelist' do
    let(:params) { { umask: '0077', user_whitelist: ['bob', 'alice'] } }

    it do
      is_expected.to contain_file('/etc/profile.d/zz-simp-umask.sh').with_content(
        "#{HEADER}for user in bob alice; do\n  if [ \"$USER\" == \"$user\" ]; then\n    return\n  fi\ndone\n\numask 0077\n",
      )
    end
    it { is_expected.to contain_file('/etc/profile.d/zz-simp-umask.csh').with_content(%r{foreach user \(bob alice\)\n  if \( "\$user" == "\$USER" \) then\n    exit\n}) }
  end

  context 'with prepend and append' do
    let(:params) do
      {
        prepend: { 'sh' => 'echo pre', 'csh' => 'absent', 'foo' => 'ignored' },
        append: { 'sh' => 'echo post', 'csh' => 'echo cpost' },
      }
    end

    it { is_expected.to contain_file('/etc/profile.d/simp-a-prepend.sh').with_content("#{HEADER}echo pre\n") }
    it { is_expected.to contain_file('/etc/profile.d/zz-simp-a-prepend.csh').with_ensure('absent') }
    it { is_expected.to contain_file('/etc/profile.d/zz-simp-z-append.sh').with_content("#{HEADER}echo post\n") }
    it { is_expected.to contain_file('/etc/profile.d/zz-simp-z-append.csh').with_content("#{HEADER}echo cpost\n") }
    it { expect(catalogue.resources.count { |r| r.type == 'File' }).to eq(4) }
  end

  context 'with legacy_simp_sh => true' do
    let(:params) { { legacy_simp_sh: true, session_timeout: 15, mesg: false, umask: '0077' } }

    it { is_expected.to contain_file('/etc/profile.d/simp.sh').with(mode: '0644', seltype: 'bin_t') }
    it { is_expected.to contain_file('/etc/profile.d/simp.sh').with_content(%r{TMOUT=900}) }
    it { is_expected.to contain_file('/etc/profile.d/simp.sh').with_content(%r{mesg n}) }
    it { is_expected.to contain_file('/etc/profile.d/simp.sh').with_content(%r{umask 0077}) }
    it { is_expected.to contain_file('/etc/profile.d/simp.csh').with_content(%r{autologout=15}) }
    it { is_expected.to contain_file('/etc/profile.d/simp.csh').with_content(%r{umask 0077}) }
    it { expect(catalogue.resources.select { |r| r.type == 'Useradd::Etc_profile::Script' }).to be_empty }
  end

  context 'with legacy_simp_sh => true and prepend and append' do
    let(:params) do
      {
        legacy_simp_sh: true,
        session_timeout: 15,
        prepend: { 'sh' => 'echo pre', 'csh' => 'echo cpre' },
        append: { 'sh' => 'echo post', 'csh' => 'absent' },
      }
    end

    it 'runs them inside the 3.x scripts' do
      is_expected.to contain_file('/etc/profile.d/simp.sh').with_content(%r{^echo pre\n\n.*TMOUT=900.*\n\necho post\n\z}m)
      is_expected.to contain_file('/etc/profile.d/simp.csh').with_content(%r{^echo cpre\n})
      is_expected.to contain_file('/etc/profile.d/simp.csh').without_content(%r{absent})
    end

    ['simp-a-prepend.sh', 'zz-simp-a-prepend.csh', 'zz-simp-z-append.sh', 'zz-simp-z-append.csh'].each do |name|
      it { is_expected.not_to contain_file("/etc/profile.d/#{name}") }
    end
  end

  context 'with legacy_simp_sh => true and umask unset' do
    let(:params) { { legacy_simp_sh: true, session_timeout: 15 } }

    it { is_expected.to contain_file('/etc/profile.d/simp.sh').without_content(%r{umask}) }
  end

  context 'with legacy_simp_sh => false' do
    let(:params) { { legacy_simp_sh: false } }

    it { is_expected.to contain_file('/etc/profile.d/simp.sh').with_ensure('absent') }
    it { is_expected.to contain_file('/etc/profile.d/simp.csh').with_ensure('absent') }
  end

  context 'with a leftover simp.sh and prepend set' do
    let(:facts) { on_supported_os.first[1].merge(useradd_legacy_simp_sh: true) }
    let(:params) { { prepend: { 'sh' => 'echo pre' } } }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.not_to contain_file('/etc/profile.d/simp.sh') }
  end
end
