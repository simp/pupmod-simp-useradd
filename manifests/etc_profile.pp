# Manage login settings for all users with scripts in /etc/profile.d
#
# Each setting is written to its own pair of `sh` and `csh` scripts, so it can
# be managed, or removed, on its own. An unset parameter leaves its scripts
# alone, and `absent` removes them.
#
# | Setting           | sh script                | csh script               |
# |-------------------|--------------------------|--------------------------|
# | `prepend`         | `simp-a-prepend.sh`      | `zz-simp-a-prepend.csh`  |
# | `session_timeout` | `simp-b-tmout.sh`        | `zz-simp-autologout.csh` |
# | `mesg`            | `zz-simp-mesg.sh`        | `zz-simp-mesg.csh`       |
# | `umask`           | `zz-simp-umask.sh`       | `zz-simp-umask.csh`      |
# | `append`          | `zz-simp-z-append.sh`    | `zz-simp-z-append.csh`   |
#
# The names order the scripts so these settings win over the `simp.sh` and
# `simp.csh` scripts written by useradd 3.x: `TMOUT` is read-only once set, so
# its script runs first, and the others run last.
#
# @param session_timeout
#   The number of *minutes* that a user may be idle prior to being
#   logged out. This is a logical extension of the SCAP Security Guide
#   requirements for Graphical and SSH timeouts and takes the place of
#   a terminal screen lock since we haven't found one that works in
#   100% of the authentication scenarios.
#
#   Sets a read-only `TMOUT` for sh, unless one is already set, and
#   `autologout` for csh.
#
# @param umask
#   The umask that will be applied to the user upon login.
#   Covers CCE-26917-5, CCE-27034-8, and CCE-26669-2
#
# @param mesg
#   If true, set mesg to allow writes to user terminals using wall,
#   etc...
#
# @param user_whitelist
#   A list of users that you don't want to be affected by these
#   settings. Every script skips them.
#
# @param prepend
#   Content for a script run before the others, as
#   `{ 'sh' => <content>, 'csh' => <content> }`. The content is written
#   exactly as provided, and `absent` removes the script. With
#   `legacy_simp_sh => true`, the content goes inside `simp.sh` and
#   `simp.csh` instead, after the `user_whitelist` check, as in 3.x.
#
#   Example:
#     { 'sh' => 'if [ $UID -eq 0 ]; then echo "foo"; fi ' }
#
# @param append
#   Content for a script run after the others. See `prepend` for usage.
#   With `legacy_simp_sh => true`, it goes at the end of `simp.sh` and
#   `simp.csh`.
#
# @param legacy_simp_sh
#   Manage `/etc/profile.d/simp.sh` and `/etc/profile.d/simp.csh`, the
#   scripts useradd 3.x wrote. `true` writes them as 3.x did, from
#   `session_timeout`, `mesg`, `umask`, `prepend` and `append`. `false`
#   removes them. Unset leaves them alone.
#
# @param manage_tmout
#   Deprecated: leave `session_timeout` unset instead. `false` stops managing
#   the session timeout.
#
# author: SIMP Team <simp@simp-project.com>
#
class useradd::etc_profile (
  Optional[Variant[Integer, Enum['absent']]] $session_timeout = undef,
  Optional[String]                           $umask           = undef,
  Optional[Variant[Boolean, Enum['absent']]] $mesg            = undef,
  Array                                      $user_whitelist  = [],
  Hash                                       $prepend         = {},
  Hash                                       $append          = {},
  Optional[Boolean]                          $legacy_simp_sh  = undef,
  Optional[Boolean]                          $manage_tmout    = undef,
) {
  if $manage_tmout =~ NotUndef {
    deprecation('useradd::etc_profile::manage_tmout', 'useradd::etc_profile::manage_tmout is deprecated and will be removed in a future release. Leave useradd::etc_profile::session_timeout unset instead.', false)
  }

  $_session_timeout = $manage_tmout ? {
    false   => undef,
    default => $session_timeout,
  }

  $_mesg = $mesg ? {
    true    => 'y',
    false   => 'n',
    default => $mesg,
  }

  # With the 3.x scripts, prepend and append run inside them, as in 3.x.
  $_extra = $legacy_simp_sh ? {
    true    => {},
    default => {
      'simp-a-prepend.sh'     => $prepend['sh'],
      'zz-simp-a-prepend.csh' => $prepend['csh'],
      'zz-simp-z-append.sh'   => $append['sh'],
      'zz-simp-z-append.csh'  => $append['csh'],
    }.filter |$name, $content| { $content =~ NotUndef }.map |$name, $content| { [$name, String($content)] }.convert_to(Hash),
  }

  $_scripts = $_extra + {
    'simp-b-tmout.sh'        => $_session_timeout ? {
      Integer => "[ \$TMOUT ] || export TMOUT=${$_session_timeout * 60}\nreadonly TMOUT",
      default => $_session_timeout,
    },
    'zz-simp-autologout.csh' => $_session_timeout ? {
      Integer => "set autologout=${_session_timeout}",
      default => $_session_timeout,
    },
    'zz-simp-mesg.sh'        => $_mesg ? {
      /\A[yn]\z/ => "if tty -s; then\n  mesg ${_mesg}\nfi",
      default    => $_mesg,
    },
    'zz-simp-mesg.csh'       => $_mesg ? {
      /\A[yn]\z/ => "tty -s\nif ( \$? == 0 ) mesg ${_mesg}",
      default    => $_mesg,
    },
    'zz-simp-umask.sh'       => $umask ? {
      'absent' => 'absent',
      default  => $umask.then |$u| { "umask ${u}" },
    },
    'zz-simp-umask.csh'      => $umask ? {
      'absent' => 'absent',
      default  => $umask.then |$u| { "umask ${u}" },
    },
  }.filter |$name, $content| { $content =~ NotUndef }

  $_scripts.each |$name, $content| {
    useradd::etc_profile::script { "/etc/profile.d/${name}":
      content        => $content,
      user_whitelist => $user_whitelist,
    }
  }

  if $legacy_simp_sh == true {
    ['sh', 'csh'].each |$ext| {
      file { "/etc/profile.d/simp.${ext}":
        ensure  => 'file',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        seltype => 'bin_t',
        content => template("useradd/etc/profile.d/simp.${ext}.erb"),
      }
    }
  }
  elsif $legacy_simp_sh == false {
    file { ['/etc/profile.d/simp.sh', '/etc/profile.d/simp.csh']:
      ensure => 'absent',
    }
  }
  elsif $facts['useradd_legacy_simp_sh'] {
    $_twice = ($prepend + $append).filter |$ext, $content| { $ext in ['sh', 'csh'] and $content != 'absent' }

    unless $_twice.empty {
      warning('useradd::etc_profile: /etc/profile.d/simp.sh or simp.csh from useradd 3.x is still present, so prepend and append content may run twice at login. Set useradd::etc_profile::legacy_simp_sh to false to remove the old scripts.')
    }
  }
}
