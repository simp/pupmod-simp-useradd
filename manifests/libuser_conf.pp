# Sets up /etc/libuser.conf.
# See libuser.conf(5) for information on the various variables.
#
class useradd::libuser_conf (
  # defaults in data/common.yaml
  Array[Enum['files','shadow','ldap']] $defaults_modules,
  Array[Enum['files','shadow','ldap']] $defaults_create_modules,
  Array[Enum['des','blowfish','sha256','sha512']] $defaults_crypt_style,
  Optional[Integer] $defaults_hash_rounds_min,
  Optional[Integer] $defaults_hash_rounds_max,
  Optional[Stdlib::AbsolutePath] $defaults_mailspooldir,
  Optional[Stdlib::AbsolutePath] $defaults_moduledir,
  Optional[Stdlib::AbsolutePath] $defaults_skeleton,
  Stdlib::AbsolutePath $import_login_defs,
  Stdlib::AbsolutePath $import_default_useradd,
  String $userdefaults,
  String $groupdefaults,
  Optional[Stdlib::AbsolutePath] $files_directory,
  Optional[Boolean] $files_nonroot,
  Optional[Stdlib::AbsolutePath] $shadow_directory,
  Optional[Boolean] $shadow_nonroot,
  Optional[String] $ldap_userbranch,
  Optional[String] $ldap_groupbranch,
  Optional[String] $ldap_server,
  Optional[String] $ldap_basedn,
  Optional[String] $ldap_binddn,
  Optional[String] $ldap_user,
  Optional[String] $ldap_password,
  Optional[String] $ldap_authuser,
  Optional[String] $ldap_bindtype,
  Optional[String] $sasl_appname,
  Optional[String] $sasl_domain
) {

  file { '/etc/libuser.conf':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('useradd/etc/libuser.conf.erb')
  }
}
