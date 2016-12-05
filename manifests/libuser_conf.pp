# Sets up /etc/libuser.conf.
# See libuser.conf(5) for information on the various variables.
#
class useradd::libuser_conf (
  Array[Enum['files','shadow','ldap']] $defaults_create_modules  = ['files','shadow'],
  Array[Enum['des','blowfish','sha256','sha512']] $defaults_crypt_style = ['sha512'],
  String $defaults_hash_rounds_min = '',
  String $defaults_hash_rounds_max = '',
  String $defaults_mailspooldir    = '',
  String $defaults_moduledir       = '',
  Array[Enum['files','shadow','ldap']] $defaults_modules = ['files','shadow'],
  String $defaults_skeleton        = '',
  $import_login_defs        = '/etc/login.defs',
  $import_default_useradd   = '/etc/default/useradd',
  String $userdefaults             = "LU_USERNAME = %n\nLU_GIDNUMBER = %u",
  String $groupdefaults            = 'LU_GROUPNAME = %n',
  String $files_directory          = '',
  String $files_nonroot            = '',
  String $shadow_directory         = '',
  String $shadow_nonroot           = '',
  String $ldap_userbranch          = '',
  String $ldap_groupbranch         = '',
  String $ldap_server              = '',
  String $ldap_basedn              = '',
  String $ldap_binddn              = '',
  String $ldap_user                = '',
  String $ldap_password            = '',
  String $ldap_authuser            = '',
  String $ldap_bindtype            = '',
  String $sasl_appname             = '',
  String $sasl_domain              = ''
) {

  file { '/etc/libuser.conf':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('useradd/etc/libuser.conf.erb')
  }
}
