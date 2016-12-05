# Set up the /etc/login.defs configuration file.
# All option values are taken directly from the system documentation.
#
# Any parameter that is a list will require an array to be passed.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class useradd::login_defs (
  Boolean $chfn_auth               = false,
  $chfn_restrict                   = 'frwh',
  Boolean $chsh_auth               = false,
  $console                         = [],
  $console_groups                  = [],
  Boolean $create_home             = true,
  Boolean $default_home            = false,
  $encrypt_method                  = 'SHA512',  # CCE-27228-6
  $env_hz                          = '',
  Array $env_path                  = [],
  Array $env_supath                = [],
  $env_tz                          = '',
  $environ_file                    = '',
  $erasechar                       = '',
  $fail_delay                      = '4',
  Boolean $faillog_enab            = true,
  $fake_shell                      = '',
  $ftmp_file                       = '',
  $gid_max                         = '500000',
  $gid_min                         = '500',
  $hushlogin_file                  = '',
  Stdlib::AbsolutePath $issue_file = '/etc/issue',
  $killchar                        = '',
  Boolean $lastlog_enab            = true,
  Boolean $log_ok_logins           = true,
  Boolean $log_unkfail_enab        = true,
  $login_retries                   = '3',
  $login_string                    = '',
  $login_timeout                   = '60',
  Boolean $mail_check_enab         = true,
  Stdlib::AbsolutePath $mail_dir   = '/var/spool/mail',
  $mail_file                       = '',
  $max_members_per_group           = '',
  $motd_file                       = [],
  $nologins_file                   = '',
  Boolean $obscure_checks_enab     = true,
  Boolean $pass_always_warn        = true,
  $pass_change_tries               = '3',
  $pass_max_days                   = '180',  # CCE-26985-2
  $pass_min_days                   = '1',    # CCE-27013-2
  $pass_warn_age                   = '14',   # CCE-26998-6
  $pass_max_len                    = '',
  $pass_min_len                    = '14',   # CCE-27002-5
  Boolean $porttime_checks_enab    = true,
  Boolean $quotas_enab             = true,
  $sha_crypt_min_rounds            = '5000',
  $sha_crypt_max_rounds            = '10000',
  $sulog_file                      = '',
  $su_name                         = 'su',
  Boolean $su_wheel_only           = false,
  $sys_gid_max                     = '',
  $sys_gid_min                     = '',
  $sys_uid_max                     = '',
  $sys_uid_min                     = '',
  Boolean $syslog_sg_enab          = true,
  Boolean $syslog_su_enab          = true,
  $ttygroup                        = '',
  $ttyperm                         = '',
  $ttytype_file                    = '',
  $uid_max                         = '1000000',
  $uid_min                         = '',
  $umask                           = '007',  # CCE-26371-5
  $ulimit                          = '',     # The maximum file size in 512 byte units. Noted here since the man page isn't helpful.
  $userdel_cmd                     = '',
  Boolean $usergroups_enab         = true
) {
  validate_re($chfn_restrict,'^[frwh]+$')
  validate_array_member($encrypt_method,['DES','MD5','SHA256','SHA512'])
  if !empty($environ_file) { validate_absolute_path($environ_file) }
  if !empty($erasechar) { validate_integer($erasechar) }
  validate_integer($fail_delay)
  if !empty($fake_shell) { validate_absolute_path($fake_shell) }
  if !empty($ftmp_file) { validate_absolute_path($ftmp_file) }
  validate_integer($gid_max)
  validate_integer($gid_min)
  if !empty($killchar) { validate_integer($killchar) }
  validate_integer($login_retries)
  validate_integer($login_timeout)
  if !empty($mail_file) { validate_absolute_path($mail_file) }
  if !empty($max_members_per_group) { validate_integer($max_members_per_group) }
  validate_array($motd_file)
  if !empty($nologins_file) { validate_absolute_path($nologins_file) }
  validate_integer($pass_change_tries)
  validate_integer($pass_max_days)
  validate_integer($pass_min_days)
  validate_integer($pass_warn_age)
  if !empty($pass_max_len) { validate_integer($pass_max_len) }
  validate_integer($pass_min_len)
  validate_integer($sha_crypt_min_rounds)
  validate_integer($sha_crypt_max_rounds)
  if !empty($sulog_file) { validate_absolute_path($sulog_file) }
  if !empty($sys_gid_max) { validate_integer($sys_gid_max) }
  if !empty($sys_gid_min) { validate_integer($sys_gid_min) }
  if !empty($sys_uid_max) { validate_integer($sys_uid_max) }
  if !empty($sys_uid_min) { validate_integer($sys_uid_min) }
  if !empty($ttyperm) { validate_umask($ttyperm) }
  if !empty($ttytype_file) { validate_absolute_path($ttytype_file) }
  validate_integer($uid_max)
  if !empty($uid_min) { validate_integer($uid_min) }
  validate_umask($umask)
  if !empty($ulimit) { validate_integer($ulimit) }
  if !empty($userdel_cmd) { validate_absolute_path($userdel_cmd) }


  file { '/etc/login.defs':
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('useradd/etc/login_defs.erb')
  }
}
