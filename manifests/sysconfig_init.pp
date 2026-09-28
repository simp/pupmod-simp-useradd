# Manage the shell run by the emergency and rescue targets
#
# `/etc/sysconfig/init` is no longer managed: no EL8 or later package ships
# it, and only the legacy `/etc/rc.d/init.d/functions` reads it. Its
# parameters are kept so existing Hiera data still compiles, and warn when set.
#
# @param single_user_login
#   The command `emergency.service` and `rescue.service` run, written to a
#   systemd drop-in for each. `absent` removes the drop-ins.
#
# @param purge
#   Remove every other drop-in for `emergency.service` and `rescue.service`.
#   Acts only while `single_user_login` is set to a command.
#
# @param systemd
#   Include the `systemd` class, which with its defaults keeps
#   `systemd-journald` running.
#
# @param bootup
#   Deprecated: ignored.
#
# @param res_col
#   Deprecated: ignored.
#
# @param move_to_col
#   Deprecated: ignored.
#
# @param setcolor_success
#   Deprecated: ignored.
#
# @param setcolor_failure
#   Deprecated: ignored.
#
# @param setcolor_warning
#   Deprecated: ignored.
#
# @param setcolor_normal
#   Deprecated: ignored.
#
# @param loglvl
#   Deprecated: ignored.
#
# @param prompt
#   Deprecated: ignored.
#
# @param autoswap
#   Deprecated: ignored.
#
# author: SIMP Team <simp@simp-project.com>
#
class useradd::sysconfig_init (
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]] $single_user_login = undef,
  Boolean                                                 $purge             = false,
  Boolean                                                 $systemd           = false,
  Optional[Useradd::Bootup]                               $bootup            = undef,
  Optional[Integer]                                       $res_col           = undef,
  Optional[String]                                        $move_to_col       = undef,
  Optional[String]                                        $setcolor_success  = undef,
  Optional[String]                                        $setcolor_failure  = undef,
  Optional[String]                                        $setcolor_warning  = undef,
  Optional[String]                                        $setcolor_normal   = undef,
  Optional[Integer[1,8]]                                  $loglvl            = undef,
  Optional[Boolean]                                       $prompt            = undef,
  Optional[Boolean]                                       $autoswap          = undef,
) {
  [
    'bootup', 'res_col', 'move_to_col', 'setcolor_success', 'setcolor_failure',
    'setcolor_warning', 'setcolor_normal', 'loglvl', 'prompt', 'autoswap',
  ].each |$param| {
    if getvar($param) =~ NotUndef {
      deprecation("useradd::sysconfig_init::${param}", "useradd::sysconfig_init::${param} is deprecated and ignored: /etc/sysconfig/init is no longer managed.", false)
    }
  }

  if $systemd {
    include 'systemd'
  }

  if $single_user_login and 'systemd' in pick($facts['init_systems'], []) {
    ['emergency', 'rescue'].each |$unit| {
      $_dir = "/etc/systemd/system/${unit}.service.d"

      if $single_user_login == 'absent' {
        file { "${_dir}/${unit}_exec.conf":
          ensure => 'absent',
          notify => Exec['useradd systemctl daemon-reload'],
        }
      }
      else {
        file { $_dir:
          ensure  => 'directory',
          owner   => 'root',
          group   => 'root',
          recurse => $purge,
          purge   => $purge,
          notify  => Exec['useradd systemctl daemon-reload'],
        }

        file { "${_dir}/${unit}_exec.conf":
          ensure  => 'file',
          owner   => 'root',
          group   => 'root',
          mode    => '0444',
          content => @("END"),
            [Service]
            ExecStart=
            ExecStart=-/bin/sh -c "${single_user_login}; /usr/bin/systemctl --fail --no-block default"
            | END
          notify  => Exec['useradd systemctl daemon-reload'],
        }
      }
    }

    exec { 'useradd systemctl daemon-reload':
      command     => 'systemctl daemon-reload',
      path        => ['/usr/bin', '/bin'],
      refreshonly => true,
    }
  }
}
