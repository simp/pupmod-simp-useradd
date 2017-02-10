require 'spec_helper'

describe 'useradd' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('useradd') }
          it { is_expected.to create_file('/etc/securetty').with_content(<<-EOF.gsub(/^\s+/,'').strip
            console
            tty1
            tty2
            tty3
            tty4
            tty5
            tty6
            ttyS0
            ttyS1
          EOF
          ) }
          it { is_expected.to create_file('/etc/shells').with_content(<<-EOF.gsub(/^\s+/,'').strip
            /bin/sh
            /bin/zsh
            /bin/bash
            /sbin/nologin
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
