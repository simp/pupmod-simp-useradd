# @summary Manage the entries of a one-entry-per-line file with augeas
#
# The file named by the title is edited in place: entries not in `entries` are
# left alone unless `purge` is on, and the file is never replaced.
#
# @param lens
#   The augeas lens that parses the file.
#
# @param entries
#   The entries, each mapped to its options. `ensure` defaults to `present`.
#
# @param purge
#   Remove every entry that isn't `present` in `entries`. Nothing is purged
#   while no entry is `present`.
#
# @param mode
#   The mode of the file, owned by `root:root`. Leaves the mode alone when
#   unset, and never creates the file.
#
# @api private
#
define useradd::entry::list (
  String[1]                                   $lens,
  Hash[Useradd::ListEntry, Useradd::EntryOptions] $entries = {},
  Boolean                                     $purge   = false,
  Optional[Stdlib::Filemode]                  $mode    = undef,
) {
  assert_private()

  $_mode_file = $mode ? {
    undef   => undef,
    default => File[$title],
  }

  $entries.each |$entry, $options| {
    useradd::entry { "${title} ${entry}":
      ensure => pick($options['ensure'], 'present'),
      file   => $title,
      lens   => $lens,
      entry  => $entry,
      before => $_mode_file,
    }
  }

  $_keep = $entries.filter |$entry, $options| { pick($options['ensure'], 'present') == 'present' }.keys

  if $purge and !$_keep.empty {
    useradd::entry::purge { $title:
      lens   => $lens,
      keep   => $_keep,
      before => $_mode_file,
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
