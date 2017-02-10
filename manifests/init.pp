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
#   List of ttys available to log into. Set to false to disable management.
#
# @param shells
#   List of shells available to the user to set as default. Set to false to
#   disable management.
#
class useradd (
  Boolean $manage_etc_profile    = true,
  Boolean $manage_libuser_conf   = true,
  Boolean $manage_login_defs     = true,
  Boolean $manage_nss            = true,
  Boolean $manage_passwd_perms   = true,
  Boolean $manage_sysconfig_init = true,
  Boolean $manage_useradd        = true,
  Variant[Boolean,Array[String]]               $securetty = [ 'console','tty1','tty2','tty3','tty4','tty5','tty6','ttyS0','ttyS1' ],
  Variant[Boolean,Array[Stdlib::AbsolutePath]] $shells = [ '/bin/sh','/bin/zsh','/bin/bash','/sbin/nologin' ]
) {

  if $manage_etc_profile    { include '::useradd::etc_profile' }
  if $manage_libuser_conf   { include '::useradd::libuser_conf' }
  if $manage_login_defs     { include '::useradd::login_defs' }
  if $manage_nss            { include '::useradd::nss' }
  if $manage_passwd_perms   { include '::useradd::passwd' }
  if $manage_sysconfig_init { include '::useradd::sysconfig_init' }
  if $manage_useradd        { include '::useradd::useradd' }

  if $securetty {
    file { '/etc/securetty':
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => join($securetty,"\n")
    }
  }

  if $shells {
    file { '/etc/shells':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => join($shells,"\n")
    }
  }

}
