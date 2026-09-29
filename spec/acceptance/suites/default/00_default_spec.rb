require 'spec_helper_acceptance'

test_name 'useradd class'

describe 'useradd class' do
  require_relative('lib/util')
  include UseraddTestUtil::ComplianceEngine

  let(:manifest) { "include 'useradd'" }

  hosts.each do |host|
    context "on #{host}" do
      # On a fresh node the Sicura console previews this module with
      # `puppet apply --noop`, which must not error. A bare include manages
      # nothing, so the preview enforces simp:defaults. This runs before
      # anything below configures the node.
      context 'in noop mode from a clean state' do
        it 'previews simp:defaults without errors' do
          with_simp_defaults_enforced(host) do
            result = apply_manifest_on(host, manifest, catch_failures: true, noop: true)
            # Guards against the preview quietly covering nothing if the
            # Compliance Engine layer stops resolving the profile.
            expect(result.output).to match(%r{Augeas\[/etc/login\.defs PASS_MAX_DAYS\]/returns: .*\(noop\)})
            expect(result.output).to match(%r{File\[/etc/profile\.d/simp\.sh\]/ensure: .*\(noop\)})
          end
        end
      end

      context 'with a bare include' do
        it 'changes nothing' do
          before = on(host, UseraddTestUtil::STATE_CMD).stdout
          apply_manifest_on(host, manifest, catch_changes: true)
          expect(on(host, UseraddTestUtil::STATE_CMD).stdout).to eq(before)
        end
      end

      # A single setting enforced alone, then un-enforced, then removed.
      context 'with one setting' do
        let(:set) { "class { 'useradd::login_defs': pass_max_days => 42 }" }
        let(:unset) { "include 'useradd::login_defs'" }
        let(:absent) { "class { 'useradd::login_defs': pass_max_days => 'absent' }" }

        it 'takes effect alone' do
          before = on(host, 'grep -v "^PASS_MAX_DAYS" /etc/login.defs').stdout
          apply_manifest_on(host, set, catch_failures: true)
          apply_manifest_on(host, set, catch_changes: true)
          expect(on(host, 'grep -E "^PASS_MAX_DAYS\s+42$" /etc/login.defs').exit_code).to eq(0)
          expect(on(host, 'grep -v "^PASS_MAX_DAYS" /etc/login.defs').stdout).to eq(before)
        end

        it 'stays when un-enforced' do
          apply_manifest_on(host, unset, catch_changes: true)
          expect(on(host, 'grep -E "^PASS_MAX_DAYS\s+42$" /etc/login.defs').exit_code).to eq(0)
        end

        it 'is removed with absent' do
          apply_manifest_on(host, absent, catch_failures: true)
          apply_manifest_on(host, absent, catch_changes: true)
          expect(on(host, 'grep -E "^PASS_MAX_DAYS" /etc/login.defs', acceptable_exit_codes: [1]).stdout).to be_empty
        end

        it 'is used by useradd' do
          apply_manifest_on(host, "class { 'useradd::login_defs': pass_max_days => 77 }", catch_failures: true)
          on(host, 'useradd -M ua_one && chage -l ua_one | grep -E "^Maximum.*: 77$"; rc=$?; userdel ua_one; exit $rc')
        end
      end

      context 'with a backslash in a value' do
        ['Pass\\word "%s":', 'Pass\\', 'Pass \\"%s\\":'].each do |value|
          it "writes #{value} verbatim" do
            set = "class { 'useradd::login_defs': login_string => '#{value.gsub(%r{[\\']}) { |c| "\\#{c}" }}' }"
            apply_manifest_on(host, set, catch_failures: true)
            apply_manifest_on(host, set, catch_changes: true)
            expect(on(host, 'grep "^LOGIN_STRING" /etc/login.defs').stdout.strip).to eq("LOGIN_STRING #{value}")
          end
        end

        it 'is removed with absent' do
          apply_manifest_on(host, "class { 'useradd::login_defs': login_string => 'absent' }", catch_failures: true)
          expect(on(host, 'grep "^LOGIN_STRING" /etc/login.defs', acceptable_exit_codes: [1]).stdout).to be_empty
        end
      end

      # 3.x wrote `login_string => ''` as the key alone on a line.
      context 'with a 3.x empty value in login.defs' do
        let(:set) { "class { 'useradd::login_defs': login_string => '', pass_max_days => 42 }" }

        it 'removes the line and applies the rest' do
          on(host, 'echo "LOGIN_STRING " >> /etc/login.defs')
          apply_manifest_on(host, set, catch_failures: true)
          apply_manifest_on(host, set, catch_changes: true)
          expect(on(host, 'grep -c "^LOGIN_STRING" /etc/login.defs', acceptable_exit_codes: [1]).stdout.strip).to eq('0')
          expect(on(host, 'grep -E "^PASS_MAX_DAYS\s+42$" /etc/login.defs').exit_code).to eq(0)
          apply_manifest_on(host, "class { 'useradd::login_defs': pass_max_days => 'absent' }", catch_failures: true)
        end
      end

      context 'with securetty_mode and no /etc/securetty' do
        let(:mode_only) { "class { 'useradd': securetty_mode => '0400' }" }

        it 'does not create the file' do
          on(host, 'rm -f /etc/securetty')
          apply_manifest_on(host, mode_only, catch_failures: true)
          apply_manifest_on(host, mode_only, catch_changes: true)
          expect(on(host, 'test -e /etc/securetty', acceptable_exit_codes: [1]).exit_code).to eq(1)
        end
      end

      context 'with shells_entries and purge_shells' do
        let(:shells) do
          <<~EOS
            class { 'useradd':
              shells_entries => { '/bin/sh' => {}, '/bin/bash' => {}, '/bin/tcsh' => { 'ensure' => 'absent' } },
              purge_shells   => true,
            }
          EOS
        end

        it 'edits /etc/shells in place' do
          on(host, 'cp -a /etc/shells /root/shells.orig && echo "/bin/tcsh" >> /etc/shells && echo "/bin/other" >> /etc/shells && sed -i "1i # site comment" /etc/shells')
          apply_manifest_on(host, shells, catch_failures: true)
          apply_manifest_on(host, shells, catch_changes: true)
          expect(on(host, 'cat /etc/shells').stdout.lines.map(&:strip)).to eq(['# site comment', '/bin/sh', '/bin/bash'])
          on(host, 'cp -a /root/shells.orig /etc/shells')
        end
      end

      context 'when enforcing simp:defaults' do
        it 'converges in one run' do
          with_simp_defaults_enforced(host) do
            apply_manifest_on(host, manifest, catch_failures: true)
            apply_manifest_on(host, manifest, catch_changes: true)
          end
        end

        it 'restores /etc/securetty' do
          expect(on(host, 'cat /etc/securetty').stdout.split).to eq(['tty0', 'tty1', 'tty2', 'tty3', 'tty4'])
          expect(on(host, 'stat -c "%a %U %G" /etc/securetty').stdout.strip).to eq('400 root root')
        end

        it 'restores login.defs, keeping the UID/GID ranges' do
          defs = on(host, 'cat /etc/login.defs').stdout
          expect(defs).to match(%r{^PASS_MAX_DAYS\s+180$})
          expect(defs).to match(%r{^UMASK\s+007$})
          expect(defs).to match(%r{^UID_MIN\s+\d+$})
          expect(defs).to match(%r{^GID_MAX\s+\d+$})
          expect(on(host, 'stat -c "%a" /etc/login.defs').stdout.strip).to eq('640')
        end

        it 'restores /etc/default/useradd' do
          expect(on(host, 'cat /etc/default/useradd').stdout).to match(%r{^INACTIVE=35$})
          expect(on(host, 'stat -c "%a" /etc/default/useradd').stdout.strip).to eq('600')
        end

        it 'restores /etc/libuser.conf' do
          conf = on(host, 'cat /etc/libuser.conf').stdout
          expect(conf).to match(%r{^crypt_style\s*=\s*sha512$})
          expect(conf).to match(%r{^LU_GIDNUMBER\s*=\s*%u$})
        end

        it 'restores the passwd file permissions' do
          expect(on(host, 'stat -c "%a %U %G" /etc/shadow').stdout.strip).to eq('0 root root')
          expect(on(host, 'stat -c "%a %U %G" /etc/passwd').stdout.strip).to eq('644 root root')
          expect(on(host, 'stat -c "%a %U %G" /etc/shells').stdout.strip).to eq('644 root root')
        end

        it 'restores the login scripts' do
          on(host, 'grep -q "TMOUT=900" /etc/profile.d/simp.sh')
          on(host, 'grep -q "autologout=15" /etc/profile.d/simp.csh')
          expect(on(host, 'bash -lc "echo \$TMOUT; umask"').stdout.split).to eq(['900', '0077'])
        end

        it 'lets a 3.x prepend and append win' do
          legacy = <<~EOS
            class { 'useradd::etc_profile':
              legacy_simp_sh  => true,
              session_timeout => 15,
              umask           => '0077',
              prepend         => { 'sh' => 'TMOUT=3600' },
              append          => { 'sh' => 'umask 0022' },
            }
          EOS
          apply_manifest_on(host, legacy, catch_failures: true)
          expect(on(host, 'bash -lc "echo \$TMOUT; umask"').stdout.split).to eq(['3600', '0022'])

          with_simp_defaults_enforced(host) do
            apply_manifest_on(host, manifest, catch_failures: true)
          end
        end

        it 'restores the single-user login drop-ins' do
          on(host, 'grep -q "/sbin/sulogin" /etc/systemd/system/rescue.service.d/rescue_exec.conf')
        end

        it 'restores /etc/sysconfig/init' do
          init = on(host, 'cat /etc/sysconfig/init').stdout
          expect(init).to match(%r{^BOOTUP="?color"?$})
          expect(init).to match(%r{^SINGLE="?/sbin/sulogin"?$})
          expect(init).to include('SETCOLOR_SUCCESS="echo -en \\\\033[0;32m"')
          expect(on(host, 'stat -c "%a" /etc/sysconfig/init').stdout.strip).to eq('644')
        end

        it 'restores /etc/default/nss' do
          expect(on(host, 'cat /etc/default/nss').stdout).to match(%r{^NETID_AUTHORITATIVE="?FALSE"?$})
          expect(on(host, 'stat -c "%a" /etc/default/nss').stdout.strip).to eq('640')
        end

        it 'is used by useradd' do
          on(host, 'useradd -M ua_two && chage -l ua_two | grep -E "^Maximum.*: 180$"; rc=$?; userdel ua_two; exit $rc')
        end
      end

      # The drop-ins exactly as 3.x wrote them through systemd::dropin_file.
      context 'with the 3.x single-user login drop-ins' do
        let(:dropin) { '/etc/systemd/system/rescue.service.d/rescue_exec.conf' }

        before(:all) do
          ['emergency', 'rescue'].each do |unit|
            on(host, <<~CMD)
              rm -rf /etc/systemd/system/#{unit}.service.d && mkdir /etc/systemd/system/#{unit}.service.d
              printf '[Service]\\nExecStart=\\nExecStart=-/bin/sh -c "/sbin/sulogin; /usr/bin/systemctl --fail --no-block default"\\n' > /etc/systemd/system/#{unit}.service.d/#{unit}_exec.conf
              chmod 0444 /etc/systemd/system/#{unit}.service.d/#{unit}_exec.conf
            CMD
          end
          on(host, 'systemctl daemon-reload')
        end

        it 'changes nothing under simp:defaults' do
          with_simp_defaults_enforced(host) do
            apply_manifest_on(host, manifest, catch_changes: true)
          end
        end

        it 'keeps them without the profile' do
          apply_manifest_on(host, manifest, catch_changes: true)
          on(host, "grep -q /sbin/sulogin #{dropin}")
          expect(on(host, "stat -c '%a %U %G' #{dropin}").stdout.strip).to eq('444 root root')
        end
      end

      context 'after simp:defaults is no longer enforced' do
        it 'reverts nothing' do
          before = on(host, UseraddTestUtil::STATE_CMD).stdout
          apply_manifest_on(host, manifest, catch_changes: true)
          expect(on(host, UseraddTestUtil::STATE_CMD).stdout).to eq(before)
        end
      end
    end
  end
end
