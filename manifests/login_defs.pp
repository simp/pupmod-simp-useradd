# Set up the /etc/login.defs configuration file.
# All option values are taken directly from the system documentation.
#
# Any parameter that is a list will require an array to be passed.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class useradd::login_defs (
  # defaults in data/common.yaml
  Enum['DES','MD5','SHA256','SHA512'] $encrypt_method,
  Boolean $chfn_auth,
  String $chfn_restrict,
  Boolean $chsh_auth,
  Optional[Array[Stdlib::AbsolutePath]] $console,
  Optional[String] $console_groups,
  Boolean $create_home,
  Boolean $default_home,
  Optional[String] $env_hz,
  Optional[Array[Stdlib::AbsolutePath]] $env_path,
  Optional[Array[Stdlib::AbsolutePath]] $env_supath,
  Optional[String] $env_tz,
  Optional[Stdlib::AbsolutePath] $environ_file,
  Optional[Integer] $erasechar,
  Integer $fail_delay,
  Boolean $faillog_enab,
  Optional[Stdlib::AbsolutePath] $fake_shell,
  Optional[Stdlib::AbsolutePath] $ftmp_file,
  Integer $gid_max,
  Integer $gid_min,
  Optional[Stdlib::AbsolutePath] $hushlogin_file,
  Stdlib::AbsolutePath $issue_file,
  Optional[Integer] $killchar,
  Boolean $lastlog_enab,
  Optional[String] $login_string,
  Integer $login_retries,
  Integer $login_timeout,
  Boolean $log_ok_logins,
  Boolean $log_unkfail_enab,
  Boolean $mail_check_enab,
  Stdlib::AbsolutePath $mail_dir,
  Optional[Stdlib::AbsolutePath] $mail_file,
  Optional[Integer] $max_members_per_group,
  Optional[Array[Stdlib::AbsolutePath]] $motd_file,
  Optional[Stdlib::AbsolutePath] $nologins_file,
  Boolean $obscure_checks_enab,
  Boolean $pass_always_warn,
  Integer $pass_change_tries,
  Integer $pass_max_days,
  Integer $pass_min_days,
  Integer $pass_warn_age,
  Optional[Integer] $pass_max_len,
  Integer $pass_min_len,
  Boolean $porttime_checks_enab,
  Boolean $quotas_enab,
  Integer $sha_crypt_min_rounds,
  Integer $sha_crypt_max_rounds,
  Optional[Stdlib::AbsolutePath] $sulog_file,
  String $su_name,
  Boolean $su_wheel_only,
  Optional[Integer] $sys_gid_max,
  Optional[Integer] $sys_gid_min,
  Optional[Integer] $sys_uid_max,
  Optional[Integer] $sys_uid_min,
  Boolean $syslog_sg_enab,
  Boolean $syslog_su_enab,
  Optional[String] $ttygroup,
  Optional[String] $ttyperm,
  Optional[Stdlib::AbsolutePath] $ttytype_file,
  Integer $uid_max,
  Optional[Integer] $uid_min,
  String $umask,
  Optional[Integer] $ulimit,
  Optional[Stdlib::AbsolutePath] $userdel_cmd,
  Boolean $usergroups_enab
) {

  validate_re($chfn_restrict,'^[frwh]+$')
  if !empty($ttyperm) { validate_umask($ttyperm) }


  file { '/etc/login.defs':
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('useradd/etc/login_defs.erb')
  }
}
