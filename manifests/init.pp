# Manage settings regarding users and user creation
#
# @param manage_useradd
#   If true, manage `/etc/default/useradd`
#
# @param manage_login_defs
#   If true, manage `/etc/login.defs`
#
# @param manage_libuser_conf
#   If true, manage `/etc/libuser.conf`
#
# @param manage_etc_profile
#   If true, manage `/etc/profile/simp.*`
#
# @param manage_sysconfig_init
#   If true, manage `/etc/sysconfig/init`
#
# @param manage_nss
#   If true, manage `/etc/default/nss`
#
# @param securetty
#   List of ttys available to log into
#
#   * Set to false to disable management
#   * If the Array is empty (default) then root will not be able to log into
#     any local device
#   * If the string 'ANY_SHELL' is found in the Array, then the
#     ``/etc/securetty`` file will be removed and root will be able to login
#     via any device.
#
# @param shells_default
#   List of shells that will appear on the system by default
#
#   * These have been set to the usual suspects and users should use the
#     ``shells`` parameter to add to the list
#
# @param shells
#   List of shells available to the user to set as default
#
#   * Set to false to disable management
#   * Will be combined with ``shells_default`` in /etc/shells
#
class useradd (
  Boolean                                      $manage_etc_profile    = true,
  Boolean                                      $manage_libuser_conf   = true,
  Boolean                                      $manage_login_defs     = true,
  Boolean                                      $manage_nss            = true,
  Boolean                                      $manage_passwd_perms   = true,
  Boolean                                      $manage_sysconfig_init = true,
  Boolean                                      $manage_useradd        = true,
  Variant[Boolean,Array[String]]               $securetty             = [],

  Array[Stdlib::AbsolutePath]                  $shells_default        = [ '/bin/sh','/bin/bash','/sbin/nologin','/usr/bin/sh','/usr/bin/bash','/usr/sbin/nologin' ],
  Variant[Boolean,Array[Stdlib::AbsolutePath]] $shells                = []
) {

  if $manage_etc_profile    { include '::useradd::etc_profile' }
  if $manage_libuser_conf   { include '::useradd::libuser_conf' }
  if $manage_login_defs     { include '::useradd::login_defs' }
  if $manage_nss            { include '::useradd::nss' }
  if $manage_passwd_perms   { include '::useradd::passwd' }
  if $manage_sysconfig_init { include '::useradd::sysconfig_init' }
  if $manage_useradd        { include '::useradd::useradd' }

  if $securetty {
    if 'ANY_SHELL' in $securetty {
      $_ensure_securetty = 'absent'
    }
    else {
      $_ensure_securetty = 'file'
    }

    file { '/etc/securetty':
      ensure  => $_ensure_securetty,
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => join($securetty,"\n")
    }
  }

  if $shells and !(empty($shells_default) and empty($shells)) {
    file { '/etc/shells':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => join(($shells_default + $shells),"\n")
    }
  }
}
