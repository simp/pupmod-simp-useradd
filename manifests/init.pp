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
#   `securetty_entries` (or the deprecated `securetty`). Nothing is purged
#   while no entry is `present`.
#
# @param securetty_mode
#   The mode of `/etc/securetty`, owned by `root:root`. Leaves the mode alone
#   when unset, and never creates the file. Defaults to `0400`, as in 3.x,
#   while the deprecated `securetty` Array is set.
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
#   `shells_entries` (or the deprecated `shells_default` and `shells`). Nothing
#   is purged while no shell is `present`.
#
# @param shells_mode
#   The mode of `/etc/shells`, owned by `root:root`. Leaves the mode alone
#   when unset, and never creates the file. Defaults to `0644`, as in 3.x,
#   while the deprecated `shells_default` or `shells` Array is set.
#
# @param securetty
#   Deprecated: use `securetty_entries`. Entries are added to `/etc/securetty`.
#
#   * `true` or `[]`: remove every entry, leaving an empty file.
#   * An Array containing `ANY_SHELL`: remove `/etc/securetty`.
#   * `false`: ignored.
#
# @param shells_default
#   Deprecated: use `shells_entries`. Shells added to `/etc/shells`.
#
# @param shells
#   Deprecated: use `shells_entries`. Shells added to `/etc/shells`, after
#   `shells_default`. `false` ignores both.
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
#   Deprecated: `useradd::nss` no longer manages anything.
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
  Optional[Variant[Boolean, Array[Useradd::Tty]]]            $securetty             = undef,
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
      $_instead = $class ? {
        'nss'   => 'useradd::nss no longer manages anything',
        default => "Set the parameters of useradd::${class} instead",
      }
      deprecation("useradd::${_param}", "useradd::${_param} is deprecated and will be removed in a future release. ${_instead}.", false)
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
      deprecation("useradd::${param}", "useradd::${param} is deprecated and will be removed in a future release. Use useradd::${_replacement} instead.", false)
    }
  }

  # /etc/securetty
  if $securetty =~ Array and 'ANY_SHELL' in $securetty {
    file { '/etc/securetty':
      ensure => 'absent',
    }
  }
  else {
    # `true` and `[]` meant an empty file in 3.x.
    $_securetty_empty = ($securetty == true or $securetty == [])
    $_securetty_legacy = $securetty ? {
      Array   => $securetty,
      default => [],
    }

    # 3.x wrote the file 0400 whenever `securetty` was in use.
    $_securetty_mode = ($securetty =~ NotUndef and $securetty != false) ? {
      true    => pick($securetty_mode, '0400'),
      default => $securetty_mode,
    }

    $_securetty_file = ($_securetty_mode or $_securetty_empty) ? {
      true    => File['/etc/securetty'],
      default => undef,
    }

    $_securetty = useradd::entries($securetty_entries, $_securetty_legacy)

    $_securetty.each |$tty, $state| {
      useradd::entry { "/etc/securetty ${tty}":
        ensure => $state,
        file   => '/etc/securetty',
        lens   => 'Securetty.lns',
        entry  => $tty,
        before => $_securetty_file,
      }
    }

    $_securetty_keep = $_securetty.filter |$tty, $state| { $state == 'present' }.keys

    if $_securetty_empty or ($purge_securetty and !$_securetty_keep.empty) {
      useradd::entry::purge { '/etc/securetty':
        lens   => 'Securetty.lns',
        keep   => $_securetty_keep,
        before => $_securetty_file,
      }
    }

    if $_securetty_file {
      # With no `ensure`, a missing file is not created.
      $_securetty_file_ensure = $_securetty_empty ? {
        true    => 'file',
        default => undef,
      }

      file { '/etc/securetty':
        ensure => $_securetty_file_ensure,
        owner  => 'root',
        group  => 'root',
        mode   => $_securetty_mode,
      }
    }
  }

  # /etc/shells
  $_shells_legacy = $shells ? {
    false   => [],
    Array   => pick($shells_default, []) + $shells,
    default => pick($shells_default, []),
  }
  $_shells = useradd::entries($shells_entries, $_shells_legacy)

  # 3.x wrote the file 0644 whenever it managed it.
  $_shells_mode = $_shells_legacy.empty ? {
    true    => $shells_mode,
    default => pick($shells_mode, '0644'),
  }

  $_shells_file = $_shells_mode ? {
    Undef   => undef,
    default => File['/etc/shells'],
  }

  $_shells.each |$shell, $state| {
    useradd::entry { "/etc/shells ${shell}":
      ensure => $state,
      file   => '/etc/shells',
      lens   => 'Shells.lns',
      entry  => $shell,
      before => $_shells_file,
    }
  }

  $_shells_keep = $_shells.filter |$shell, $state| { $state == 'present' }.keys

  if $purge_shells and !$_shells_keep.empty {
    useradd::entry::purge { '/etc/shells':
      lens   => 'Shells.lns',
      keep   => $_shells_keep,
      before => $_shells_file,
    }
  }

  if $_shells_file {
    # With no `ensure`, a missing file is not created.
    file { '/etc/shells':
      owner => 'root',
      group => 'root',
      mode  => $_shells_mode,
    }
  }
}
