require 'spec_helper_acceptance'

test_name 'useradd class'

servers = hosts_with_role(hosts, 'server')
servers.each do |server|
  describe 'useradd class' do
    # On a fresh node the Sicura console previews this module with
    # `puppet apply --noop`, which must not error. Exercise that here before
    # the real applies below. No package-removal step: useradd manages config
    # files only, so noop-only is the representative check. We noop the
    # default-management manifest (`class { 'useradd': }`), which is what the
    # console previews for the module class (the no-management manifest below
    # deliberately manages nothing, so it is not representative).
    context 'in noop mode from a clean state' do
      let(:noop_manifest) do
        <<-EOS
        class { 'useradd': }
        EOS
      end

      it 'applies without errors in noop mode' do
        apply_manifest_on(server, noop_manifest, catch_failures: true, noop: true)
      end
    end

    context 'parameters set to false (no management)' do
      let(:manifest_with_no_management) do
        <<-EOS
        class { 'useradd':
          manage_etc_profile    => false,
          manage_libuser_conf   => false,
          manage_login_defs     => false,
          manage_nss            => false,
          manage_passwd_perms   => false,
          manage_sysconfig_init => false,
          manage_useradd        => false,
          shells_default        => [],
        }
        EOS
      end

      it 'modifies files to test management' do
        on(server, 'chmod 777 /etc/passwd /etc/passwd- /etc/shadow /etc/shadow- /etc/gshadow /etc/gshadow- /etc/group /etc/group-')
        on(server,
'echo "management_test" | tee -a /etc/profile.d/simp.sh /etc/profile.d/simp.csh /etc/libuser.conf /etc/default/nss /etc/sysconfig/init /etc/login.defs /etc/default/useradd > /dev/null')
      end

      it 'works with no errors' do
        apply_manifest_on(server, manifest_with_no_management, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(server, manifest_with_no_management, catch_changes: true)
      end

      it 'does not manage /etc/profile.d/simp.sh' do
        result = on(server, 'cat /etc/profile.d/simp.sh').stdout
        expect(result).to include('management_test')
      end

      it 'does not manage /etc/profile.d/simp.csh' do
        result = on(server, 'cat /etc/profile.d/simp.csh').stdout
        expect(result).to include('management_test')
      end

      it 'does not manage /etc/libuser.conf' do
        result = on(server, 'cat /etc/libuser.conf').stdout
        expect(result).to include('management_test')
      end

      it 'does not manage /etc/default/nss' do
        result = on(server, 'cat /etc/default/nss').stdout
        expect(result).to include('management_test')
      end

      it 'does not manage /etc/sysconfig/init' do
        result = on(server, 'cat /etc/sysconfig/init').stdout
        expect(result).to include('management_test')
      end

      it 'does not manage /etc/login.defs' do
        result = on(server, 'cat /etc/login.defs').stdout
        expect(result).to include('management_test')
      end

      it 'does not manage /etc/default/useradd' do
        result = on(server, 'cat /etc/default/useradd').stdout
        expect(result).to include('management_test')
      end

      it 'does not manage /etc/passwd' do
        result = on(server, 'stat -c "%a %n" /etc/passwd').stdout
        expect(result).to include('777 /etc/passwd')
      end

      it 'does not manage /etc/passwd-' do
        result = on(server, 'stat -c "%a %n" /etc/passwd-').stdout
        expect(result).to include('777 /etc/passwd-')
      end

      it 'does not manage /etc/shadow' do
        result = on(server, 'stat -c "%a %n" /etc/shadow').stdout
        expect(result).to include('777 /etc/shadow')
      end

      it 'does not manage /etc/shadow-' do
        result = on(server, 'stat -c "%a %n" /etc/shadow-').stdout
        expect(result).to include('777 /etc/shadow-')
      end

      it 'does not manage /etc/gshadow' do
        result = on(server, 'stat -c "%a %n" /etc/gshadow').stdout
        expect(result).to include('777 /etc/gshadow')
      end

      it 'does not manage /etc/gshadow-' do
        result = on(server, 'stat -c "%a %n" /etc/gshadow-').stdout
        expect(result).to include('777 /etc/gshadow-')
      end

      it 'does not manage /etc/group' do
        result = on(server, 'stat -c "%a %n" /etc/group').stdout
        expect(result).to include('777 /etc/group')
      end

      it 'does not manage /etc/group-' do
        result = on(server, 'stat -c "%a %n" /etc/group-').stdout
        expect(result).to include('777 /etc/group-')
      end
    end

    context 'default parameters (management)' do
      let(:manifest) do
        <<-EOS
      class { 'useradd':
      }
        EOS
      end

      it 'works with no errors' do
        apply_manifest_on(server, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(server, manifest, catch_changes: true)
      end

      it 'manages /etc/profile.d/simp.sh' do
        result = on(server, 'cat /etc/profile.d/simp.sh').stdout
        expect(result).to include('# This file managed by Puppet.')
      end

      it 'manages /etc/profile.d/simp.csh' do
        result = on(server, 'cat /etc/profile.d/simp.csh').stdout
        expect(result).to include('# This file managed by Puppet.')
      end

      it 'manages /etc/libuser' do
        result = on(server, 'cat /etc/libuser.conf').stdout
        expect(result).to include('# This file managed by Puppet.')
      end

      it 'manages /etc/default/nss' do
        result = on(server, 'cat /etc/default/nss').stdout
        expect(result).to include('# This file managed by Puppet.')
      end

      it 'manages /etc/login.defs' do
        result = on(server, 'cat /etc/login.defs').stdout
        expect(result).to include('# This file managed by Puppet.')
      end

      it 'manages /etc/default/useradd' do
        result = on(server, 'cat /etc/default/useradd').stdout
        expect(result).to include('# This file managed by Puppet.')
      end

      it 'manages /etc/passwd' do
        result = on(server, 'stat -c "%a %n" /etc/passwd').stdout
        expect(result).to include('644 /etc/passwd')
      end

      it 'manages /etc/passwd-' do
        result = on(server, 'stat -c "%a %n" /etc/passwd-').stdout
        expect(result).to include('644 /etc/passwd-')
      end

      it 'manages /etc/shadow' do
        result = on(server, 'stat -c "%a %n" /etc/shadow').stdout
        expect(result).to include('0 /etc/shadow')
      end

      it 'manages /etc/shadow-' do
        result = on(server, 'stat -c "%a %n" /etc/shadow-').stdout
        expect(result).to include('0 /etc/shadow-')
      end

      it 'manages /etc/gshadow' do
        result = on(server, 'stat -c "%a %n" /etc/gshadow').stdout
        expect(result).to include('0 /etc/gshadow')
      end

      it 'manages /etc/gshadow-' do
        result = on(server, 'stat -c "%a %n" /etc/gshadow-').stdout
        expect(result).to include('0 /etc/gshadow-')
      end

      it 'manages /etc/group' do
        result = on(server, 'stat -c "%a %n" /etc/group').stdout
        expect(result).to include('644 /etc/group')
      end

      it 'manages /etc/group-' do
        result = on(server, 'stat -c "%a %n" /etc/group-').stdout
        expect(result).to include('644 /etc/group-')
      end

      it '/etc/securetty should be empty' do
        result = on(server, 'cat /etc/securetty').stdout
        expect(result).to include('tty0', 'tty1', 'tty2', 'tty3', 'tty4')
      end

      it 'contains /etc/shells with content from shells default array' do
        result = on(server, 'cat /etc/shells').stdout
        expect(result).to include('/bin/sh', '/bin/bash', '/sbin/nologin', '/usr/bin/sh', '/usr/bin/bash', '/usr/sbin/nologin')
      end
    end

    context 'with securetty defined' do
      let(:manifest_with_securetty_defined) do
        <<-EOS
      class { 'useradd':
        securetty => ['console', 'tty0', 'tty1', 'tty2'],
      }
        EOS
      end

      it 'works with no errors' do
        apply_manifest_on(server, manifest_with_securetty_defined, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(server, manifest_with_securetty_defined, catch_changes: true)
      end

      it 'adds content to /etc/securetty' do
        result = on(server, 'cat /etc/securetty').stdout
        expect(result).to include('console', 'tty0', 'tty1', 'tty2')
      end
    end

    context 'with securetty set to ANY_SHELL' do
      let(:manifest_with_securetty_absent) do
        <<-EOS
      class { 'useradd':
        securetty => ['ANY_SHELL'],
      }
        EOS
      end

      it 'works with no errors' do
        apply_manifest_on(server, manifest_with_securetty_absent, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(server, manifest_with_securetty_absent, catch_changes: true)
      end

      it 'removes /etc/securetty' do
        result = on(server, 'test -f /etc/securetty', { acceptable_exit_codes: [0, 1] })
        expect(result.exit_code).not_to eq(0)
      end
    end

    context 'with shells defined' do
      let(:manifest_with_shells_defined) do
        <<-EOS
      class { 'useradd':
        shells => ['/bin/csh'],
      }
        EOS
      end

      it 'works with no errors' do
        apply_manifest_on(server, manifest_with_shells_defined, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(server, manifest_with_shells_defined, catch_changes: true)
      end

      it 'adds shell variable content to /etc/shells' do
        result = on(server, 'cat /etc/shells').stdout
        expect(result).to include('/bin/sh', '/bin/bash', '/sbin/nologin', '/usr/bin/sh', '/usr/bin/bash', '/usr/sbin/nologin', '/bin/csh')
      end
    end

    context 'with login.defs set' do
      let(:manifest_logindefs) do
        <<-EOS

        class { 'useradd::login_defs':
          encrypt_method        => 'MD5',
          chfn_auth             => true,
          max_members_per_group => 10,
          nologins_file         => '/etc/nologins',
          pass_min_days         => 0,
          pass_max_days         => 100,
          pass_warn_age         => 20,
        }

        EOS
      end

      it 'works with no errors' do
        apply_manifest_on(server, manifest_logindefs, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(server, manifest_logindefs, catch_changes: true)
      end

      it 'edits /etc/login.defs' do
        result = on(server, 'cat /etc/login.defs').stdout
        expect(result).to include('ENCRYPT_METHOD MD5', 'CHFN_AUTH yes', 'MAX_MEMBERS_PER_GROUP 10', 'NOLOGINS_FILE /etc/nologins', 'PASS_MIN_DAYS 0', 'PASS_MAX_DAYS 100', 'PASS_WARN_AGE 20')
      end

      it 'updates new user accounts' do
        on(server, 'chmod 777 /etc/passwd /etc/passwd- /etc/shadow /etc/shadow- /etc/gshadow /etc/gshadow- /etc/group /etc/group-')
        on(server, 'useradd defsuser -p password')
        result = on(server, 'chage -l defsuser').stdout
        expect(result).to match(%r{^Minimum number of days between password change\s*:\s*0$})
        expect(result).to match(%r{^Maximum number of days between password change\s*:\s*100$})
        expect(result).to match(%r{^Number of days of warning before password expires\s*:\s*20$})
      end
    end

    context 'with parameters set' do
      let(:manifest_with_parameters_set) do
        <<-EOS
        class { 'useradd::etc_profile':
          session_timeout => 30,
          umask           => '0777',
          mesg            => true,
          user_whitelist  => ['test', 'test2'],
          prepend         => { 'sh' => 'echo sh prepend', 'csh' => 'echo csh prepend' },
          append          => { 'sh' => 'echo sh append', 'csh' => 'echo csh append' },
        }

        class { 'useradd::libuser_conf':
          defaults_modules         => [],
          defaults_create_modules  => ['files','shadow','ldap'],
          defaults_crypt_style     => 'md5',
          defaults_hash_rounds_min => 1000,
          defaults_hash_rounds_max => 5000,
          defaults_mailspooldir    => '/etc/mailspooldir',
          defaults_moduledir       => '/etc/moduledir',
          defaults_skeleton        => '/etc/skeleton',
          import_login_defs        => '/etc/login.defs.test',
          import_default_useradd   => '/etc/default/useradd.test',
          files_directory          => '/etc/files',
          files_nonroot            => true,
          shadow_directory         => '/etc/shadowdir',
          shadow_nonroot           => true,
          ldap_userbranch          => 'ou=Test_User_Branch',
          ldap_groupbranch         => 'ou=Test_Group_Branch',
          ldap_server              => 'www.example.com',
          ldap_basedn              => 'dc=test,dc=com',
          ldap_binddn              => 'cn=bind_manage,dc=test,dc=com',
          ldap_user                => 'ldap_user',
          ldap_password            => 'ldappasswd',
          ldap_authuser            => 'ldap_authuser',
          ldap_bindtype            => 'sasl,sasl/XOAUTH',
          sasl_appname             => 'test_app',
          sasl_domain              => 'www.testappdomain.com',
        }

        class { 'useradd::nss':
          netid_authoritative    => true,
          services_authoritative => true,
          setent_batch_read      => false,
        }

        class { 'useradd::useradd':
          group             => 101,
          home              => '/useradd_home',
          inactive          => 50,
          expire            => '2017-06-26',
          shell             => '/bin/csh',
          skel              => '/etc/skel_test',
          create_mail_spool => false,
        }

        class { 'useradd::sysconfig_init':
          bootup            => 'verbose',
          res_col           => 75,
          setcolor_success  => 'cyan',
          setcolor_failure  => 'magenta',
          setcolor_warning  => 'blue',
          setcolor_normal   => '"echo -en \\\\\\033[0;31m"',
          single_user_login => '/sbin/sulogin_test',
          loglvl            => 7,
          prompt            => true,
          autoswap          => true,
        }

        class { 'useradd::login_defs':
          encrypt_method        => 'MD5',
          chfn_auth             => true,
          max_members_per_group => 10,
          nologins_file         => '/etc/nologins',
          pass_min_days         => 0,
          pass_max_days         => 100,
          pass_warn_age         => 20,
        }

        EOS
      end

      it 'works with no errors' do
        apply_manifest_on(server, manifest_with_parameters_set, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(server, manifest_with_parameters_set, catch_changes: true)
      end

      it 'edits /etc/profile.d/simp.sh' do
        result = on(server, 'cat /etc/profile.d/simp.sh').stdout
        expect(result).to include('TMOUT=1800', 'umask 0777', 'mesg y', 'for user in test test2; do', 'echo sh prepend', 'echo sh append')
      end

      it 'edits /etc/profile.d/simp.csh' do
        result = on(server, 'cat /etc/profile.d/simp.csh').stdout
        expect(result).to include('set autologout=30', 'umask 0777', 'mesg y', 'foreach user (test test2)', 'echo csh prepend', 'echo csh append')
      end

      it 'edits /etc/libuser.conf' do
        result = on(server, 'cat /etc/libuser.conf').stdout
        # rubocop:disable Layout/LineLength
        expect(result).to include(
          "[import]\nlogin_defs = /etc/login.defs.test\ndefault_useradd = /etc/default/useradd.test", "[defaults]\ncreate_modules = files,shadow,ldap\ncrypt_style = md5\nhash_rounds_min = 1000\nhash_rounds_max = 5000\nmailspooldir = /etc/mailspooldir\nmoduledir = /etc/moduledir\nskeleton = /etc/skeleton", "[files]\ndirectory = /etc/files\nnonroot = yes", "[shadow]\ndirectory = /etc/shadowdir\nnonroot = yes", "[ldap]\nuserBranch = ou=Test_User_Branch\ngroupBranch = ou=Test_Group_Branch\nserver = www.example.com\nbasedn = dc=test,dc=com\nbinddn = cn=bind_manage,dc=test,dc=com\nuser = ldap_user\npassword = ldappasswd\nauthuser = ldap_authuser\nbindtype = sasl,sasl/XOAUTH", "[sasl]\nappname = test_app\ndomain = www.testappdomain.com"
        )
        # rubocop:enable Layout/LineLength
      end

      it 'edits /etc/default/nss' do
        result = on(server, 'cat /etc/default/nss').stdout
        expect(result).to include('NETID_AUTHORITATIVE=TRUE', 'SERVICES_AUTHORITATIVE=TRUE', 'SETENT_BATCH_READ=FALSE')
      end

      it 'edits /etc/default/useradd' do
        result = on(server, 'cat /etc/default/useradd').stdout
        expect(result).to include('GROUP=101', 'HOME=/useradd_home', 'INACTIVE=50', 'EXPIRE=2017-06-26', 'SHELL=/bin/csh', 'SKEL=/etc/skel_test', 'CREATE_MAIL_SPOOL=no')
      end

      it 'edits /etc/sysconfig/init' do
        result = on(server, 'cat /etc/sysconfig/init').stdout
        expect(result).to include('BOOTUP=verbose', 'RES_COL=75', 'MOVE_TO_COL="echo -en \\\\033[${RES_COL}G"', 'SETCOLOR_SUCCESS="echo -en \\\\033[0;36m"',
                                  'SETCOLOR_FAILURE="echo -en \\\\033[0;35m"', 'SETCOLOR_WARNING="echo -en \\\\033[0;34m"', 'SETCOLOR_NORMAL="echo -en \\\\033[0;31m"',
                                  'SINGLE=/sbin/sulogin_test', 'LOGLEVEL=7', 'PROMPT=yes', 'AUTOSWAP=yes')
      end
    end
  end
end
