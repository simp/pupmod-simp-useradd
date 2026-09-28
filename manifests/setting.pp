# @summary Set, or remove, one key in a configuration file with augeas
#
# The file is edited in place. Keys the module doesn't manage are left alone.
#
# @param file
#   The file to edit.
#
# @param lens
#   The augeas lens that parses `file`.
#
# @param key
#   The augeas path of the key, relative to the file (`section/key` for INI
#   style files).
#
# @param value
#   The value to set, or `absent` to remove the key. Booleans are written as
#   `yes`/`no`.
#
# @api private
#
define useradd::setting (
  Stdlib::AbsolutePath              $file,
  String[1]                         $lens,
  String[1]                         $key,
  Variant[Boolean, Integer, String] $value,
) {
  assert_private()

  if $value == 'absent' {
    $_changes = "rm ${key}"
    $_onlyif  = "match ${key} size > 0"
  }
  else {
    $_value = $value ? {
      true    => 'yes',
      false   => 'no',
      default => String($value),
    }
    # The augeas provider passes `\x` through verbatim and unescapes only
    # `\"`, so only `"` is escaped. A backslash before a `"`, or at the end,
    # would then end the string early.
    if $_value =~ /\\("|\z)/ {
      fail("useradd::setting '${title}': a value can't have a backslash before a double quote or at the end")
    }
    $_escaped = $_value.regsubst('"', '\\"', 'G')

    $_changes = "set ${key} \"${_escaped}\""
    $_onlyif  = undef
  }

  augeas { $title:
    incl    => $file,
    lens    => $lens,
    context => "/files${file}",
    changes => $_changes,
    onlyif  => $_onlyif,
  }
}
