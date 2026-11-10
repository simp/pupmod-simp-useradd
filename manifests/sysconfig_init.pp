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
#   With `systemd => true`, the drop-ins are written with
#   `systemd::dropin_file` while this matches `systemd::purge_dropin_dirs`.
#   Otherwise they're plain `file` resources, and their directories are
#   declared with the attributes `systemd::dropin_file` uses in the installed
#   puppet/systemd. Another module's `systemd::dropin_file` on these units can
#   then declare the same directory only if it agrees on the purge. If it
#   doesn't, the catalog fails with a duplicate declaration, since the two
#   would disagree on whether to remove each other's drop-ins.
#
# @param systemd
#   Include the `systemd` class, which with its defaults keeps
#   `systemd-journald` running. The drop-ins are then written with
#   `systemd::dropin_file`, unless `purge_dropins` differs from
#   `systemd::purge_dropin_dirs`.
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

  # With `systemd => true` and its purge setting, systemd::dropin_file manages
  # the drop-ins, their directories and the daemon-reload, so they can't
  # diverge from another module's drop-ins on these units.
  $_use_dropin_file = $systemd and $_purge_dropins == $systemd::purge_dropin_dirs

  if $single_user_login and 'systemd' in pick($facts['init_systems'], []) {
    if $single_user_login == 'absent' {
      $_ensure = 'absent'
      $_content = undef
    }
    else {
      $_ensure = 'present'
      $_content = @("END")
        [Service]
        ExecStart=
        ExecStart=-/bin/sh -c "${single_user_login}; /usr/bin/systemctl --fail --no-block default"
        | END
    }

    # The directory attributes `systemd::dropin_file` uses in the installed
    # puppet/systemd, so either can declare the directory first while they
    # agree on the purge. puppet/systemd 11 added the mode.
    $_systemd_version = load_module_metadata('systemd', true)['version']
    $_dir_mode = ($_systemd_version and versioncmp($_systemd_version, '11.0.0') >= 0) ? {
      true    => { mode => '0755' },
      default => {},
    }

    ['emergency', 'rescue'].each |$unit| {
      $_dir = "/etc/systemd/system/${unit}.service.d"

      if $_use_dropin_file {
        # Namespaced, so the title can't collide with a site's own drop-ins.
        # The drop-in never restarts or refreshes the unit: that would start
        # the rescue or emergency target.
        systemd::dropin_file { "useradd ${unit}_exec.conf":
          ensure         => $_ensure,
          unit           => "${unit}.service",
          filename       => "${unit}_exec.conf",
          mode           => '0444',
          content        => $_content,
          notify_service => false,
        }
      }
      elsif $_ensure == 'absent' {
        file { "${_dir}/${unit}_exec.conf":
          ensure => 'absent',
          notify => Exec['useradd systemctl daemon-reload'],
        }
      }
      else {
        ensure_resource('file', $_dir, {
          ensure                  => 'directory',
          owner                   => 'root',
          group                   => 'root',
          recurse                 => $_purge_dropins,
          purge                   => $_purge_dropins,
          selinux_ignore_defaults => false,
        } + $_dir_mode)

        file { "${_dir}/${unit}_exec.conf":
          ensure  => 'file',
          owner   => 'root',
          group   => 'root',
          mode    => '0444',
          content => $_content,
          notify  => Exec['useradd systemctl daemon-reload'],
        }
      }
    }

    unless $_use_dropin_file {
      exec { 'useradd systemctl daemon-reload':
        command     => 'systemctl daemon-reload',
        path        => ['/usr/bin', '/bin'],
        refreshonly => true,
      }
    }
  }
}
