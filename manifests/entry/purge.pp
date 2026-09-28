# @summary Remove every entry from a one-entry-per-line file except the ones listed
#
# The file is edited in place: comments stay, and the file is never replaced.
# An empty `keep` removes every entry.
#
# @param keep
#   The entries to keep.
#
# @param lens
#   The augeas lens that parses the file named by the title.
#
# @api private
#
define useradd::entry::purge (
  String[1]                                $lens,
  Array[Pattern[/\A[A-Za-z0-9_.:\/-]+\z/]] $keep = [],
) {
  assert_private()

  $_path = "*[label() != '#comment'${keep.map |$e| { " and . != '${e}'" }.join}]"

  augeas { "${title} purge":
    incl    => $title,
    lens    => $lens,
    context => "/files${title}",
    changes => "rm ${_path}",
    onlyif  => "match ${_path} size > 0",
  }
}
