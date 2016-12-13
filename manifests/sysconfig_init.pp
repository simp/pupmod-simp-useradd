# Allow for the configuration of /etc/sysconfig/init
#
# See /usr/share/doc/initscripts-<version>/sysconfig.txt for variable
#   definitions.
#
# @param bootup
# @param res_col
# @param move_to_col
# @param setcolor_success
# @param setcolor_failure
# @param setcolor_warning
# @param setcolor_normal
# @param single_user_login
# @param loglvl
# @param prompt
# @param autoswap
#
class useradd::sysconfig_init (
  Useradd::Bootup      $bootup            = 'color',
  Integer              $res_col           = 60,
  String               $move_to_col       = "\"echo -en \\\\033[\${RES_COL}G\"",
  String               $setcolor_success  = "\"echo -en \\\\033[0;32m\"",
  String               $setcolor_failure  = "\"echo -en \\\\033[0;31m\"",
  String               $setcolor_warning  = "\"echo -en \\\\033[0;33m\"",
  String               $setcolor_normal   = "\"echo -en \\\\033[0;39m\"",
  Stdlib::AbsolutePath $single_user_login = '/sbin/sulogin',
  Integer[1,8]         $loglvl            = 3,
  Boolean              $prompt            = false,
  Boolean              $autoswap          = false,
) {

  file { '/etc/sysconfig/init':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('simplib/etc/sysconfig/init.erb')
  }
}
