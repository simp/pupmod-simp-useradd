# Manage settings in /etc/sysconfig/init, and the shell run by the emergency
# and rescue targets
#
# Each display parameter manages the key of the same name, upper-cased (`loglvl`
# manages `LOGLEVEL`), editing the file in place. An unset parameter leaves its
# key alone, and `absent` removes the key.
#
# @param single_user_login
#   The command `emergency.service` and `rescue.service` run, written to a
#   systemd drop-in for each, and to `SINGLE`. `absent` removes the drop-ins
#   and the key.
#
# @param purge_dropins
#   Remove every other drop-in for `emergency.service` and `rescue.service`.
#   Acts only while `single_user_login` is set to a command. Defaults to
#   `systemd::purge_dropin_dirs` with `systemd => true`, and to `false`
#   otherwise.
#
#   The drop-in directories are declared the way `systemd::dropin_file`
#   declares them, so both can add drop-ins to these units as long as they
#   agree on the purge. Otherwise the catalog fails with a duplicate
#   declaration.
#
# @param systemd
#   Include the `systemd` class, which with its defaults keeps
#   `systemd-journald` running.
#
# @param bootup
# @param res_col
# @param move_to_col
#   Written as provided.
#
# @param setcolor_success
#   An ANSI color name (`black`, `red`, `green`, `yellow`, `blue`, `magenta`,
#   `cyan`, `white` or `default`), written as the `echo` command that sets it,
#   or any other value, written as provided.
#
# @param setcolor_failure
#   See `setcolor_success`.
#
# @param setcolor_warning
#   See `setcolor_success`.
#
# @param setcolor_normal
#   See `setcolor_success`.
#
# @param loglvl
# @param prompt
#   Written as `yes`/`no`.
#
# @param autoswap
#   Written as `yes`/`no`.
#
# @param mode
#   The mode of `/etc/sysconfig/init`, owned by `root:root`. Leaves the mode
#   alone when unset.
#
# @param purge
#   Remove every key from `/etc/sysconfig/init` the class doesn't set.
#   Comments stay. Nothing is purged while no key is set.
#
# author: SIMP Team <simp@simp-project.com>
#
class useradd::sysconfig_init (
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]] $single_user_login = undef,
  Optional[Boolean]                                       $purge_dropins     = undef,
  Boolean                                                 $systemd           = false,
  Optional[Variant[Useradd::Bootup, Enum['absent']]]      $bootup            = undef,
  Optional[Variant[Integer, Enum['absent']]]              $res_col           = undef,
  Optional[String]                                        $move_to_col       = undef,
  Optional[String]                                        $setcolor_success  = undef,
  Optional[String]                                        $setcolor_failure  = undef,
  Optional[String]                                        $setcolor_warning  = undef,
  Optional[String]                                        $setcolor_normal   = undef,
  Optional[Variant[Integer[1,8], Enum['absent']]]         $loglvl            = undef,
  Optional[Variant[Boolean, Enum['absent']]]              $prompt            = undef,
  Optional[Variant[Boolean, Enum['absent']]]              $autoswap          = undef,
  Optional[Stdlib::Filemode]                              $mode              = undef,
  Boolean                                                 $purge             = false,
) {
  $_ansi = {
    'black'   => 30,
    'red'     => 31,
    'green'   => 32,
    'yellow'  => 33,
    'blue'    => 34,
    'magenta' => 35,
    'cyan'    => 36,
    'white'   => 37,
    'default' => 39,
  }.map |$name, $code| { [$name, "\"echo -en \\\\033[0;${code}m\""] }.convert_to(Hash)

  $_settings = {
    'BOOTUP'           => $bootup,
    'RES_COL'          => $res_col,
    'MOVE_TO_COL'      => $move_to_col,
    'SETCOLOR_SUCCESS' => $setcolor_success.then |$c| { $_ansi[$c].lest || { $c } },
    'SETCOLOR_FAILURE' => $setcolor_failure.then |$c| { $_ansi[$c].lest || { $c } },
    'SETCOLOR_WARNING' => $setcolor_warning.then |$c| { $_ansi[$c].lest || { $c } },
    'SETCOLOR_NORMAL'  => $setcolor_normal.then |$c| { $_ansi[$c].lest || { $c } },
    'SINGLE'           => $single_user_login,
    'LOGLEVEL'         => $loglvl,
    'PROMPT'           => $prompt,
    'AUTOSWAP'         => $autoswap,
  }.filter |$key, $value| { $value =~ NotUndef }

  useradd::settings { '/etc/sysconfig/init':
    lens     => 'Shellvars.lns',
    settings => $_settings,
    mode     => $mode,
    purge    => $purge,
  }

  if $systemd {
    include 'systemd'

    $_purge_dropins = pick($purge_dropins, $systemd::purge_dropin_dirs)
  }
  else {
    $_purge_dropins = pick($purge_dropins, false)
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
        # The same attributes as `systemd::dropin_file`, so either can declare
        # the directory first.
        ensure_resource('file', $_dir, {
          ensure                  => 'directory',
          owner                   => 'root',
          group                   => 'root',
          recurse                 => $_purge_dropins,
          purge                   => $_purge_dropins,
          selinux_ignore_defaults => false,
        })

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
