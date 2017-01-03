# Set up the /etc/login.defs configuration file.
# All option values are taken directly from the system documentation.
#
# Any parameter that is a list will require an array to be passed.
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
# @param gid_min
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
# @param uid_min
# @param umask
# @param ulimit
# @param userdel_cmd
# @param usergroups_enab
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class useradd::login_defs (
  Enum['DES','MD5','SHA256','SHA512']     $encrypt_method        = 'SHA512',  # CCE-27228-6
  Boolean                                 $chfn_auth             = false,
  Pattern['^[frwh]+$']                    $chfn_restrict         = 'frwh',
  Boolean                                 $chsh_auth             = false,
  Optional[Array[Stdlib::AbsolutePath,1]] $console               = undef,
  Optional[Array[String,1]]               $console_groups        = undef,
  Boolean                                 $create_home           = true,
  Boolean                                 $default_home          = false,
  Optional[String]                        $env_hz                = undef,
  Optional[Array[Stdlib::AbsolutePath,1]] $env_path              = undef,
  Optional[Array[Stdlib::AbsolutePath,1]] $env_supath            = undef,
  Optional[String]                        $env_tz                = undef,
  Optional[Stdlib::AbsolutePath]          $environ_file          = undef,
  Optional[Integer]                       $erasechar             = undef,
  Integer                                 $fail_delay            = 4,
  Boolean                                 $faillog_enab          = true,
  Optional[Stdlib::AbsolutePath]          $fake_shell            = undef,
  Optional[Stdlib::AbsolutePath]          $ftmp_file             = undef,
  Integer                                 $gid_max               = 500000,
  Integer                                 $gid_min               = 500,
  Optional[Stdlib::AbsolutePath]          $hushlogin_file        = undef,
  Stdlib::AbsolutePath                    $issue_file            = '/etc/issue',
  Optional[Integer]                       $killchar              = undef,
  Boolean                                 $lastlog_enab          = true,
  Optional[String]                        $login_string          = undef,
  Integer                                 $login_retries         = 3,
  Integer                                 $login_timeout         = 60,
  Boolean                                 $log_ok_logins         = true,
  Boolean                                 $log_unkfail_enab      = true,
  Boolean                                 $mail_check_enab       = true,
  Stdlib::AbsolutePath                    $mail_dir              = '/var/spool/mail',
  Optional[Stdlib::AbsolutePath]          $mail_file             = undef,
  Optional[Integer]                       $max_members_per_group = undef,
  Optional[Array[Stdlib::AbsolutePath,1]] $motd_file             = undef,
  Optional[Stdlib::AbsolutePath]          $nologins_file         = undef,
  Boolean                                 $obscure_checks_enab   = true,
  Boolean                                 $pass_always_warn      = true,
  Integer                                 $pass_change_tries     = 3,
  Integer                                 $pass_max_days         = 180,  # CCE-26985-2
  Integer                                 $pass_min_days         = 1,    # CCE-27013-2
  Integer                                 $pass_warn_age         = 14,   # CCE-26998-6
  Optional[Integer]                       $pass_max_len          = undef,
  Integer                                 $pass_min_len          = 14,   # CCE-27002-5
  Boolean                                 $porttime_checks_enab  = true,
  Boolean                                 $quotas_enab           = true,
  Integer                                 $sha_crypt_min_rounds  = 5000,
  Integer                                 $sha_crypt_max_rounds  = 10000,
  Optional[Stdlib::AbsolutePath]          $sulog_file            = undef,
  String                                  $su_name               = 'su',
  Boolean                                 $su_wheel_only         = false,
  Optional[Integer]                       $sys_gid_max           = undef,
  Optional[Integer]                       $sys_gid_min           = undef,
  Optional[Integer]                       $sys_uid_max           = undef,
  Optional[Integer]                       $sys_uid_min           = undef,
  Boolean                                 $syslog_sg_enab        = true,
  Boolean                                 $syslog_su_enab        = true,
  Optional[String]                        $ttygroup              = undef,
  Optional[String]                        $ttyperm               = undef,
  Optional[Stdlib::AbsolutePath]          $ttytype_file          = undef,
  Integer                                 $uid_max               = 1000000,
  Optional[Integer]                       $uid_min               = undef,
  String                                  $umask                 = '007',  # CCE-26371-5
  Optional[Integer]                       $ulimit                = undef,  # The maximum file size in 512 byte units. Noted here since the man page isn't helpful.
  Optional[Stdlib::AbsolutePath]          $userdel_cmd           = undef,
  Boolean                                 $usergroups_enab       = true
) {

  if $ttyperm { validate_umask($ttyperm) }

  file { '/etc/login.defs':
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('useradd/etc/login_defs.erb')
  }
}
