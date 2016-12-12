# Sets up /etc/libuser.conf.
# See libuser.conf(5) for information on the various variables.
#
class useradd::libuser_conf (
  Array[Useradd::LibuserModule]  $defaults_modules         = ['files','shadow'],
  Array[Useradd::LibuserModule]  $defaults_create_modules  = ['files','shadow'],
  Useradd::CryptStyle            $defaults_crypt_style     = ['sha512'],
  Optional[Integer]              $defaults_hash_rounds_min = undef,
  Optional[Integer]              $defaults_hash_rounds_max = undef,
  Optional[Stdlib::AbsolutePath] $defaults_mailspooldir    = undef,
  Optional[Stdlib::AbsolutePath] $defaults_moduledir       = undef,
  Optional[Stdlib::AbsolutePath] $defaults_skeleton        = undef,
  Stdlib::AbsolutePath           $import_login_defs        = '/etc/login.defs',
  Stdlib::AbsolutePath           $import_default_useradd   = '/etc/default/useradd',
  String                         $userdefaults             = "LU_USERNAME = %n\nLU_GIDNUMBER = %u",
  String                         $groupdefaults            = 'LU_GROUPNAME = %n',
  Optional[Stdlib::AbsolutePath] $files_directory          = undef,
  Optional[Boolean]              $files_nonroot            = undef,
  Optional[Stdlib::AbsolutePath] $shadow_directory         = undef,
  Optional[Boolean]              $shadow_nonroot           = undef,
  Optional[String]               $ldap_userbranch          = undef,
  Optional[String]               $ldap_groupbranch         = undef,
  Optional[String]               $ldap_server              = undef,
  Optional[String]               $ldap_basedn              = undef,
  Optional[String]               $ldap_binddn              = undef,
  Optional[String]               $ldap_user                = undef,
  Optional[String]               $ldap_password            = undef,
  Optional[String]               $ldap_authuser            = undef,
  Optional[String]               $ldap_bindtype            = undef,
  Optional[String]               $sasl_appname             = undef,
  Optional[String]               $sasl_domain              = undef
) {

  file { '/etc/libuser.conf':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('useradd/etc/libuser.conf.erb')
  }
}
