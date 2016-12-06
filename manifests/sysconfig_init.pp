# Allow for the configuration of /etc/sysconfig/init
#
# See /usr/share/doc/initscripts-<version>/sysconfig.txt for variable
#   definitions.
#
class useradd::sysconfig_init (
  # defaults in data/common.yaml
  Enum['color','verbose','plain'] $bootup,
  Integer $res_col,
  String $move_to_col,
  String $setcolor_success,
  String $setcolor_failure,
  String $setcolor_warning,
  String $setcolor_normal,
  Stdlib::AbsolutePath $single_user_login,
  Integer[1,8] $loglvl,
  Boolean $prompt,
  Boolean $autoswap
) {

  file { '/etc/sysconfig/init':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('simplib/etc/sysconfig/init.erb')
  }
}
