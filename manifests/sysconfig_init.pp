# Allow for the configuration of /etc/sysconfig/init
#
# See /usr/share/doc/initscripts-<version>/sysconfig.txt for variable
#   definitions.
#
# @param bootup
# @param res_col
# @param move_to_col
#   * By default, undef will add the code `"echo -en \\033[${RES_COL}G"` to
#     /etc/sysconfig/init
#   * Optional string of code will be substituted if included
# @param setcolor_success
# @param setcolor_failure
# @param setcolor_warning
# @param setcolor_normal
# @param single_user_login
# @param loglvl
# @param prompt
# @param autoswap
#   AUTOSWAP option is only useful in el6.  Not present in el7 or later.
#
#For all `setcolor` variables, use the following color options as a string:
#   * default
#   * black
#   * red
#   * green
#   * yellow
#   * blue
#   * magenta
#   * cyan
#   * white
#
# author: SIMP Team <simp@simp-project.com>
#
class useradd::sysconfig_init (
  Useradd::Bootup      $bootup            = 'color',
  Integer              $res_col           = 60,
  Optional[String]     $move_to_col       = undef,
  String               $setcolor_success  = 'green',
  String               $setcolor_failure  = 'red',
  String               $setcolor_warning  = 'yellow',
  String               $setcolor_normal   = 'default',
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
    content => template('useradd/etc/sysconfig/init.erb')
  }
}
