# @summary Add, or remove, one entry in a one-entry-per-line file with augeas
#
# Used for `/etc/securetty` and `/etc/shells`. Other entries are left alone.
#
# @param file
#   The file to edit.
#
# @param lens
#   The augeas lens that parses `file`.
#
# @param entry
#   The entry.
#
# @param ensure
#   Whether the entry is in the file.
#
# @api private
#
define useradd::entry (
  Stdlib::AbsolutePath                  $file,
  String[1]                             $lens,
  Pattern[/\A[A-Za-z0-9_.:\/-]+\z/]     $entry,
  Enum['present', 'absent']             $ensure = 'present',
) {
  assert_private()

  $_match = "*[label() != '#comment' and . = '${entry}']"

  if $ensure == 'present' {
    $_changes = "set 01[last()+1] ${entry}"
    $_onlyif  = "match ${_match} size == 0"
  }
  else {
    $_changes = "rm ${_match}"
    $_onlyif  = "match ${_match} size > 0"
  }

  augeas { $title:
    incl    => $file,
    lens    => $lens,
    context => "/files${file}",
    changes => $_changes,
    onlyif  => $_onlyif,
  }
}
