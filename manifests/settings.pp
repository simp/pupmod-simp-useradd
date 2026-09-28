# @summary Manage keys in one configuration file with augeas
#
# The file named by the title is edited in place: keys not in `settings` are
# left alone unless `purge` is on, and the file is never replaced.
#
# @param lens
#   The augeas lens that parses the file.
#
# @param settings
#   The keys to manage, mapped to their values. `absent` removes a key.
#
# @param mode
#   The mode of the file, owned by `root:root`. Leaves the mode alone when
#   unset, and never creates the file.
#
# @param purge
#   Remove every key not in `settings`. Nothing is purged while no key is set.
#
# @param sections
#   The file is INI style, and each key is `section/key`.
#
# @param purge_exclude
#   Keys `purge` never removes.
#
# @api private
#
define useradd::settings (
  String[1]                                          $lens,
  Hash[String[1], Variant[Boolean, Integer, String]] $settings,
  Optional[Stdlib::Filemode]                         $mode          = undef,
  Boolean                                            $purge         = false,
  Boolean                                            $sections      = false,
  Array[String[1]]                                   $purge_exclude = [],
) {
  assert_private()

  $_mode_file = $mode ? {
    undef   => undef,
    default => File[$title],
  }

  $settings.each |$key, $value| {
    useradd::setting { "${title} ${key}":
      file   => $title,
      lens   => $lens,
      key    => $key,
      value  => $value,
      before => $_mode_file,
    }
  }

  $_keep = $settings.filter |$key, $value| { $value != 'absent' }.keys

  if $purge and !$_keep.empty {
    useradd::purge { "${title} purge":
      file     => $title,
      lens     => $lens,
      keep     => ($_keep + $purge_exclude).unique,
      sections => $sections,
      before   => $_mode_file,
    }
  }

  if $mode {
    # With no `ensure`, a missing file is not created.
    file { $title:
      owner => 'root',
      group => 'root',
      mode  => $mode,
    }
  }
}
