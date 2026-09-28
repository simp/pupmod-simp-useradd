# Manage settings regarding users and user creation
#
# A bare `include useradd` manages nothing. Each setting is managed only when
# its parameter is set. To restore the behavior of useradd 3.x, enforce the
# `simp:defaults` compliance profile:
#
#   compliance_engine::enforcement:
#     - simp:defaults
#
# @param securetty_entries
#   ttys root may log in from, each mapped to its options. `{}` adds the tty
#   to `/etc/securetty` in place.
#
# @option securetty_entries [Enum['present', 'absent']] :ensure
#   `absent` removes the tty. Defaults to `present`.
#
# @param purge_securetty
#   Remove every entry from `/etc/securetty` that isn't `present` in
#   `securetty_entries`. Nothing is purged while no entry is `present`.
#
# @param securetty_mode
#   The mode of `/etc/securetty`, owned by `root:root`. Leaves the mode alone
#   when unset, and never creates the file.
#
# @param shells_entries
#   Shells, each mapped to its options. `{}` adds the shell to `/etc/shells`
#   in place.
#
# @option shells_entries [Enum['present', 'absent']] :ensure
#   `absent` removes the shell. Defaults to `present`.
#
# @param purge_shells
#   Remove every shell from `/etc/shells` that isn't `present` in
#   `shells_entries`. Nothing is purged while no shell is `present`.
#
# @param shells_mode
#   The mode of `/etc/shells`, owned by `root:root`. Leaves the mode alone
#   when unset, and never creates the file.
#
# @param securetty
#   Deprecated: use `securetty_entries`. As in 3.x, owns the whole of
#   `/etc/securetty` (mode `securetty_mode`, default `0400`), and
#   `securetty_entries` and `purge_securetty` are ignored:
#
#   * An Array: exactly these ttys.
#   * `true` or `[]`: an empty file.
#   * An Array containing `ANY_SHELL`: `/etc/securetty` is removed.
#   * `false`: `/etc/securetty` is left alone.
#
# @param shells_default
#   Deprecated: use `shells_entries`. As in 3.x, owns the whole of
#   `/etc/shells` (mode `shells_mode`, default `0644`), listing these shells
#   and then `shells`, and `shells_entries` and `purge_shells` are ignored.
#   Defaults to the 3.x list while only `shells` is set.
#
# @param shells
#   Deprecated: use `shells_entries`. Shells listed in `/etc/shells` after
#   `shells_default`, as in 3.x. `false` leaves `/etc/shells` alone.
#
# @param manage_etc_profile
#   Deprecated: set the parameters of `useradd::etc_profile` instead. `false`
#   skips the class.
#
# @param manage_libuser_conf
#   Deprecated: set the parameters of `useradd::libuser_conf` instead. `false`
#   skips the class.
#
# @param manage_login_defs
#   Deprecated: set the parameters of `useradd::login_defs` instead. `false`
#   skips the class.
#
# @param manage_nss
#   Deprecated: set the parameters of `useradd::nss` instead. `false` skips
#   the class.
#
# @param manage_passwd_perms
#   Deprecated: set `useradd::passwd::files` instead. `false` skips the class.
#
# @param manage_sysconfig_init
#   Deprecated: set the parameters of `useradd::sysconfig_init` instead.
#   `false` skips the class.
#
# @param manage_useradd
#   Deprecated: set the parameters of `useradd::useradd` instead. `false`
#   skips the class.
#
# author: SIMP Team <simp@simp-project.com>
#
class useradd (
  Hash[Useradd::Tty, Useradd::EntryOptions]                  $securetty_entries     = {},
  Boolean                                                    $purge_securetty       = false,
  Optional[Stdlib::Filemode]                                 $securetty_mode        = undef,
  Hash[Stdlib::AbsolutePath, Useradd::EntryOptions]          $shells_entries        = {},
  Boolean                                                    $purge_shells          = false,
  Optional[Stdlib::Filemode]                                 $shells_mode           = undef,
  Optional[Variant[Boolean, Array[String]]]                  $securetty             = undef,
  Optional[Array[Stdlib::AbsolutePath]]                      $shells_default        = undef,
  Optional[Variant[Boolean, Array[Stdlib::AbsolutePath]]]    $shells                = undef,
  Optional[Boolean]                                          $manage_etc_profile    = undef,
  Optional[Boolean]                                          $manage_libuser_conf   = undef,
  Optional[Boolean]                                          $manage_login_defs     = undef,
  Optional[Boolean]                                          $manage_nss            = undef,
  Optional[Boolean]                                          $manage_passwd_perms   = undef,
  Optional[Boolean]                                          $manage_sysconfig_init = undef,
  Optional[Boolean]                                          $manage_useradd        = undef,
) {
  {
    'etc_profile'    => $manage_etc_profile,
    'libuser_conf'   => $manage_libuser_conf,
    'login_defs'     => $manage_login_defs,
    'nss'            => $manage_nss,
    'passwd'         => $manage_passwd_perms,
    'sysconfig_init' => $manage_sysconfig_init,
    'useradd'        => $manage_useradd,
  }.each |$class, $manage| {
    if $manage =~ NotUndef {
      $_param = $class ? {
        'passwd' => 'manage_passwd_perms',
        default  => "manage_${class}",
      }
      simplib::deprecation("useradd::${_param}", "useradd::${_param} is deprecated and will be removed in a future release. Set the parameters of useradd::${class} instead.")
    }

    unless $manage == false {
      include "useradd::${class}"
    }
  }

  ['securetty', 'shells_default', 'shells'].each |$param| {
    if getvar($param) =~ NotUndef {
      $_replacement = $param ? {
        'securetty' => 'securetty_entries',
        default     => 'shells_entries',
      }
      simplib::deprecation("useradd::${param}", "useradd::${param} is deprecated and will be removed in a future release. Use useradd::${_replacement} instead.")
    }
  }

  # The deprecated parameters keep their 3.x behavior: once set, each owns its
  # whole file, and the matching `*_entries`, purge and mode parameters are
  # ignored for it. `false` leaves the file alone.

  # /etc/securetty
  if $securetty =~ NotUndef {
    if $securetty =~ Array and 'ANY_SHELL' in $securetty {
      file { '/etc/securetty':
        ensure => 'absent',
      }
    }
    elsif $securetty != false {
      # `true` meant an empty file in 3.x.
      $_ttys = $securetty ? {
        Array   => $securetty,
        default => [],
      }

      file { '/etc/securetty':
        ensure  => 'file',
        owner   => 'root',
        group   => 'root',
        mode    => pick($securetty_mode, '0400'),
        content => $_ttys.join("\n"),
      }
    }
  }
  else {
    useradd::entry::list { '/etc/securetty':
      lens    => 'Securetty.lns',
      entries => $securetty_entries,
      purge   => $purge_securetty,
      mode    => $securetty_mode,
    }
  }

  # /etc/shells
  $_shells_default_3x = [
    '/bin/sh', '/bin/bash', '/sbin/nologin', '/usr/bin/sh', '/usr/bin/bash', '/usr/sbin/nologin',
  ]

  if $shells_default =~ NotUndef or $shells =~ NotUndef {
    unless $shells == false {
      $_shells_legacy = pick($shells_default, $_shells_default_3x) + ($shells ? {
        Array   => $shells,
        default => [],
      })

      unless $_shells_legacy.empty {
        file { '/etc/shells':
          owner   => 'root',
          group   => 'root',
          mode    => pick($shells_mode, '0644'),
          content => $_shells_legacy.join("\n"),
        }
      }
    }
  }
  else {
    useradd::entry::list { '/etc/shells':
      lens    => 'Shells.lns',
      entries => $shells_entries,
      purge   => $purge_shells,
      mode    => $shells_mode,
    }
  }
}
