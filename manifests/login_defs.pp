# Manage settings in /etc/login.defs
#
# Each parameter manages the login.defs key of the same name, upper-cased,
# editing the file in place. An unset parameter leaves its key alone, and
# `absent` removes the key. Booleans are written as `yes`/`no`, and Arrays are
# joined as login.defs expects.
#
# All option values are taken directly from the system documentation.
#
# @param encrypt_method
# @param chfn_auth
# @param chfn_restrict
# @param chsh_auth
# @param console
# @param console_groups
# @param create_home
# @param default_home
# @param env_hz
# @param env_path
# @param env_supath
# @param env_tz
# @param environ_file
# @param erasechar
# @param fail_delay
# @param faillog_enab
# @param fake_shell
# @param ftmp_file
# @param gid_max
#   Defaults to `simp_options::gid::max`, when set.
# @param gid_min
#   Defaults to `simp_options::gid::min`, when set.
# @param hushlogin_file
# @param issue_file
# @param killchar
# @param lastlog_enab
# @param login_string
# @param login_retries
# @param login_timeout
# @param log_ok_logins
# @param log_unkfail_enab
# @param mail_check_enab
# @param mail_dir
# @param mail_file
# @param max_members_per_group
# @param motd_file
# @param nologins_file
# @param obscure_checks_enab
# @param pass_always_warn
# @param pass_change_tries
# @param pass_max_days
# @param pass_min_days
# @param pass_warn_age
# @param pass_max_len
# @param pass_min_len
# @param porttime_checks_enab
# @param quotas_enab
# @param sha_crypt_min_rounds
# @param sha_crypt_max_rounds
# @param sulog_file
# @param su_name
# @param su_wheel_only
# @param sys_gid_max
# @param sys_gid_min
# @param sys_uid_max
# @param sys_uid_min
# @param syslog_sg_enab
# @param syslog_su_enab
# @param ttygroup
# @param ttyperm
# @param ttytype_file
# @param uid_max
#   Defaults to `simp_options::uid::max`, when set.
# @param uid_min
#   Defaults to `simp_options::uid::min`, when set.
# @param umask
# @param ulimit
# @param userdel_cmd
# @param usergroups_enab
#
# NOTE: pass_min_len and pass_max_len will NOT have any effect on a stock RedHat machine.
#     * Max length will only affect 3des encryption, which is not used on modern machines.
#     * Min length should be configured using /etc/pam.d/ or /etc/security/pwquality.conf.
#
# @param mode
#   The mode of `/etc/login.defs`, owned by `root:root`. Leaves the mode alone
#   when unset.
#
# @param purge
#   Remove every key the class doesn't set. Comments stay. Nothing is purged
#   while no key is set. `UID_MIN`, `UID_MAX`, `GID_MIN` and `GID_MAX` are
#   never purged, so the ranges on the system stay when they aren't set here.
#
# author: SIMP Team <simp@simp-project.com>
#
class useradd::login_defs (
  Optional[Variant[Enum['DES','MD5','SHA256','SHA512'], Enum['absent']]] $encrypt_method        = undef,  # CCE-27228-6
  Optional[Variant[Boolean, Enum['absent']]]                             $chfn_auth             = undef,
  Optional[Variant[Pattern['^[frwh]+$'], Enum['absent']]]                $chfn_restrict         = undef,
  Optional[Variant[Boolean, Enum['absent']]]                             $chsh_auth             = undef,
  Optional[Variant[Array[Stdlib::AbsolutePath,1], Enum['absent']]]       $console               = undef,
  Optional[Variant[Array[String,1], Enum['absent']]]                     $console_groups        = undef,
  Optional[Variant[Boolean, Enum['absent']]]                             $create_home           = undef,
  Optional[Variant[Boolean, Enum['absent']]]                             $default_home          = undef,
  Optional[Variant[String, Enum['absent']]]                              $env_hz                = undef,
  Optional[Variant[Array[Stdlib::AbsolutePath,1], Enum['absent']]]       $env_path              = undef,
  Optional[Variant[Array[Stdlib::AbsolutePath,1], Enum['absent']]]       $env_supath            = undef,
  Optional[Variant[String, Enum['absent']]]                              $env_tz                = undef,
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]]                $environ_file          = undef,
  Optional[Variant[Integer, Enum['absent']]]                             $erasechar             = undef,
  Optional[Variant[Integer, Enum['absent']]]                             $fail_delay            = undef,
  Optional[Variant[Boolean, Enum['absent']]]                             $faillog_enab          = undef,
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]]                $fake_shell            = undef,
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]]                $ftmp_file             = undef,
  Optional[Variant[Integer[0], Enum['absent']]]                          $gid_min               = simplib::lookup('simp_options::gid::min', { 'default_value' => undef }),
  Optional[Variant[Integer[1], Enum['absent']]]                          $gid_max               = simplib::lookup('simp_options::gid::max', { 'default_value' => undef }),
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]]                $hushlogin_file        = undef,
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]]                $issue_file            = undef,
  Optional[Variant[Integer, Enum['absent']]]                             $killchar              = undef,
  Optional[Variant[Boolean, Enum['absent']]]                             $lastlog_enab          = undef,
  Optional[Variant[String, Enum['absent']]]                              $login_string          = undef,
  Optional[Variant[Integer, Enum['absent']]]                             $login_retries         = undef,
  Optional[Variant[Integer, Enum['absent']]]                             $login_timeout         = undef,
  Optional[Variant[Boolean, Enum['absent']]]                             $log_ok_logins         = undef,
  Optional[Variant[Boolean, Enum['absent']]]                             $log_unkfail_enab      = undef,
  Optional[Variant[Boolean, Enum['absent']]]                             $mail_check_enab       = undef,
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]]                $mail_dir              = undef,
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]]                $mail_file             = undef,
  Optional[Variant[Integer, Enum['absent']]]                             $max_members_per_group = undef,
  Optional[Variant[Array[Stdlib::AbsolutePath,1], Enum['absent']]]       $motd_file             = undef,
  Optional[Stdlib::Filemode]                                             $mode                  = undef,
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]]                $nologins_file         = undef,
  Optional[Variant[Boolean, Enum['absent']]]                             $obscure_checks_enab   = undef,
  Optional[Variant[Boolean, Enum['absent']]]                             $pass_always_warn      = undef,
  Optional[Variant[Integer, Enum['absent']]]                             $pass_change_tries     = undef,
  Optional[Variant[Integer, Enum['absent']]]                             $pass_max_days         = undef,  # CCE-26985-2
  Optional[Variant[Integer, Enum['absent']]]                             $pass_min_days         = undef,  # CCE-27013-2
  Optional[Variant[Integer, Enum['absent']]]                             $pass_warn_age         = undef,  # CCE-26998-6
  Optional[Variant[Integer, Enum['absent']]]                             $pass_max_len          = undef,
  Optional[Variant[Integer, Enum['absent']]]                             $pass_min_len          = undef,  # CCE-27002-5
  Optional[Variant[Boolean, Enum['absent']]]                             $porttime_checks_enab  = undef,
  Optional[Variant[Boolean, Enum['absent']]]                             $quotas_enab           = undef,
  Optional[Variant[Integer, Enum['absent']]]                             $sha_crypt_min_rounds  = undef,
  Optional[Variant[Integer, Enum['absent']]]                             $sha_crypt_max_rounds  = undef,
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]]                $sulog_file            = undef,
  Optional[Variant[String, Enum['absent']]]                              $su_name               = undef,
  Optional[Variant[Boolean, Enum['absent']]]                             $su_wheel_only         = undef,
  Optional[Variant[Integer, Enum['absent']]]                             $sys_gid_max           = undef,
  Optional[Variant[Integer, Enum['absent']]]                             $sys_gid_min           = undef,
  Optional[Variant[Integer, Enum['absent']]]                             $sys_uid_max           = undef,
  Optional[Variant[Integer, Enum['absent']]]                             $sys_uid_min           = undef,
  Optional[Variant[Boolean, Enum['absent']]]                             $syslog_sg_enab        = undef,
  Optional[Variant[Boolean, Enum['absent']]]                             $syslog_su_enab        = undef,
  Optional[Variant[String, Enum['absent']]]                              $ttygroup              = undef,
  Optional[Variant[Simplib::Umask, Enum['absent']]]                      $ttyperm               = undef,
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]]                $ttytype_file          = undef,
  Optional[Variant[Integer[0], Enum['absent']]]                          $uid_min               = simplib::lookup('simp_options::uid::min', { 'default_value' => undef }),
  Optional[Variant[Integer[1], Enum['absent']]]                          $uid_max               = simplib::lookup('simp_options::uid::max', { 'default_value' => undef }),
  Optional[Variant[String, Enum['absent']]]                              $umask                 = undef,  # CCE-26371-5
  Optional[Variant[Integer, Enum['absent']]]                             $ulimit                = undef,  # The maximum file size in 512 byte units. Noted here since the man page isn't helpful.
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]]                $userdel_cmd           = undef,
  Optional[Variant[Boolean, Enum['absent']]]                             $usergroups_enab       = undef,
  Boolean                                                                $purge                 = false
) {
  # The Login_defs lens can't hold a key with no value, so an empty String is
  # skipped. 3.x wrote it as `KEY` with nothing after it, which the lens can't
  # parse either, so that line is removed before any edit.
  $_empty = {
    'console_groups' => $console_groups =~ Array and '' in $console_groups,
    'login_string'   => $login_string == '',
    'su_name'        => $su_name == '',
    'ttygroup'       => $ttygroup == '',
    'umask'          => $umask == '',
  }.filter |$param, $empty| { $empty }.keys

  $_empty.each |$param| {
    deprecation("useradd::login_defs::${param}", "useradd::login_defs::${param}: an empty value is deprecated and ignored; login.defs can't hold it.", false)

    $_key = $param.upcase
    file_line { "/etc/login.defs ${_key} empty":
      ensure            => 'absent',
      path              => '/etc/login.defs',
      match             => "^\\s*${_key}\\s*$",
      match_for_absence => true,
      multiple          => true,
      before            => Useradd::Settings['/etc/login.defs'],
    }
  }

  $_env_hz = $env_hz ? {
    Undef       => undef,
    'absent'    => 'absent',
    /^HZ=/      => $env_hz,
    default     => "HZ=${env_hz}",
  }
  $_env_tz = $env_tz ? {
    Undef       => undef,
    'absent'    => 'absent',
    /^(\/|TZ=)/ => $env_tz,
    default     => "TZ=${env_tz}",
  }

  $_settings = {
    'CHFN_AUTH'             => $chfn_auth,
    'CHFN_RESTRICT'         => $chfn_restrict,
    'CHSH_AUTH'             => $chsh_auth,
    'CONSOLE'               => useradd::join($console, ':'),
    'CONSOLE_GROUPS'        => useradd::join($console_groups ? { Array => $console_groups - [''], default => $console_groups }, ','),
    'CREATE_HOME'           => $create_home,
    'DEFAULT_HOME'          => $default_home,
    'ENCRYPT_METHOD'        => $encrypt_method,
    'ENV_HZ'                => $_env_hz,
    'ENV_PATH'              => useradd::join($env_path, ':'),
    'ENV_SUPATH'            => useradd::join($env_supath, ':'),
    'ENV_TZ'                => $_env_tz,
    'ENVIRON_FILE'          => $environ_file,
    'ERASECHAR'             => $erasechar,
    'FAIL_DELAY'            => $fail_delay,
    'FAILLOG_ENAB'          => $faillog_enab,
    'FAKE_SHELL'            => $fake_shell,
    'FTMP_FILE'             => $ftmp_file,
    'GID_MAX'               => $gid_max,
    'GID_MIN'               => $gid_min,
    'HUSHLOGIN_FILE'        => $hushlogin_file,
    'ISSUE_FILE'            => $issue_file,
    'KILLCHAR'              => $killchar,
    'LASTLOG_ENAB'          => $lastlog_enab,
    'LOG_OK_LOGINS'         => $log_ok_logins,
    'LOG_UNKFAIL_ENAB'      => $log_unkfail_enab,
    'LOGIN_RETRIES'         => $login_retries,
    'LOGIN_STRING'          => $login_string,
    'LOGIN_TIMEOUT'         => $login_timeout,
    'MAIL_CHECK_ENAB'       => $mail_check_enab,
    'MAIL_DIR'              => $mail_dir,
    'MAIL_FILE'             => $mail_file,
    'MAX_MEMBERS_PER_GROUP' => $max_members_per_group,
    'MOTD_FILE'             => useradd::join($motd_file, ':'),
    'NOLOGINS_FILE'         => $nologins_file,
    'OBSCURE_CHECKS_ENAB'   => $obscure_checks_enab,
    'PASS_ALWAYS_WARN'      => $pass_always_warn,
    'PASS_CHANGE_TRIES'     => $pass_change_tries,
    'PASS_MAX_DAYS'         => $pass_max_days,
    'PASS_MIN_DAYS'         => $pass_min_days,
    'PASS_WARN_AGE'         => $pass_warn_age,
    'PASS_MAX_LEN'          => $pass_max_len,
    'PASS_MIN_LEN'          => $pass_min_len,
    'PORTTIME_CHECKS_ENAB'  => $porttime_checks_enab,
    'QUOTAS_ENAB'           => $quotas_enab,
    'SHA_CRYPT_MIN_ROUNDS'  => $sha_crypt_min_rounds,
    'SHA_CRYPT_MAX_ROUNDS'  => $sha_crypt_max_rounds,
    'SULOG_FILE'            => $sulog_file,
    'SU_NAME'               => $su_name,
    'SU_WHEEL_ONLY'         => $su_wheel_only,
    'SYS_GID_MAX'           => $sys_gid_max,
    'SYS_GID_MIN'           => $sys_gid_min,
    'SYS_UID_MAX'           => $sys_uid_max,
    'SYS_UID_MIN'           => $sys_uid_min,
    'SYSLOG_SG_ENAB'        => $syslog_sg_enab,
    'SYSLOG_SU_ENAB'        => $syslog_su_enab,
    'TTYGROUP'              => $ttygroup,
    'TTYPERM'               => $ttyperm,
    'TTYTYPE_FILE'          => $ttytype_file,
    'UID_MAX'               => $uid_max,
    'UID_MIN'               => $uid_min,
    'UMASK'                 => $umask,
    'ULIMIT'                => $ulimit,
    'USERDEL_CMD'           => $userdel_cmd,
    'USERGROUPS_ENAB'       => $usergroups_enab,
  }.filter |$key, $value| { $value =~ NotUndef and $value != '' }

  useradd::settings { '/etc/login.defs':
    lens          => 'Login_defs.lns',
    settings      => $_settings,
    mode          => $mode,
    purge         => $purge,
    purge_exclude => ['UID_MIN', 'UID_MAX', 'GID_MIN', 'GID_MAX'],
  }
}
