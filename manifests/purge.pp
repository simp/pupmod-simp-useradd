# @summary Remove every key from a configuration file except the ones listed
#
# The file is edited in place: comments stay, and the file is never replaced.
#
# @param file
#   The file to edit.
#
# @param lens
#   The augeas lens that parses `file`.
#
# @param keep
#   The keys to keep. With `sections`, each is `section/key`.
#
# @param sections
#   The file is INI style. Keys are purged within each section, and sections
#   with no key in `keep` lose every key.
#
# @api private
#
define useradd::purge (
  Stdlib::AbsolutePath                     $file,
  String[1]                                $lens,
  Array[Pattern[/\A[A-Za-z0-9_\/]+\z/], 1] $keep,
  Boolean                                  $sections = false,
) {
  assert_private()

  if $sections {
    $_by_section = $keep.reduce({}) |$memo, $path| {
      $_parts = $path.split('/')
      $memo + { $_parts[0] => pick($memo[$_parts[0]], []) + [$_parts[1]] }
    }

    $_managed = $_by_section.map |$section, $keys| {
      "${section}/*[label() != '#comment'${keys.map |$k| { " and label() != '${k}'" }.join}]"
    }
    $_unmanaged = "*[${_by_section.keys.map |$s| { "label() != '${s}'" }.join(' and ')}]/*[label() != '#comment']"
    $_paths = $_managed + [$_unmanaged]
  }
  else {
    $_paths = ["*[label() != '#comment'${keep.map |$k| { " and label() != '${k}'" }.join}]"]
  }

  $_paths.each |$index, $path| {
    augeas { "${title} ${index}":
      incl    => $file,
      lens    => $lens,
      context => "/files${file}",
      changes => "rm ${path}",
      onlyif  => "match ${path} size > 0",
    }
  }
}
