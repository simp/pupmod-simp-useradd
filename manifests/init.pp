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
class useradd (
  Boolean $manage_useradd      = true,
  Boolean $manage_login_defs   = true,
  Boolean $manage_libuser_conf = true,
  Boolean $manage_etc_profile  = true
) {

  if $manage_useradd {
    include '::useradd::useradd'
  }

  if $manage_login_defs {
    include '::useradd::login_defs'
  }

  if $manage_libuser_conf {
    include '::useradd::libuser_conf'
  }

  if $manage_etc_profile {
    include '::useradd::etc_profile'
  }

}