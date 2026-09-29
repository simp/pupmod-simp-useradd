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
    # The augeas provider unescapes only the quote in a quoted argument, so a
    # backslash before that quote, or at the end, ends it early. An unquoted
    # argument is read verbatim up to the next space.
    $_quote = ['"', "'"].filter |$q| { $_value !~ Regexp("\\\\(${q}|\\z)") }[0]

    if $_quote {
      $_changes = "set ${key} ${_quote}${_value.regsubst($_quote, "\\\\${_quote}", 'G')}${_quote}"
    }
    elsif $_value =~ /\A[^\s'"]\S*\z/ {
      $_changes = "set ${key} ${_value}"
    }
    else {
      fail("useradd::setting '${title}': augeas can't write a value with a space or a leading quote that ends in a backslash or has one before both a \" and a '")
    }
    $_onlyif = undef
  }

  augeas { $title:
    incl    => $file,
    lens    => $lens,
    context => "/files${file}",
    changes => $_changes,
    onlyif  => $_onlyif,
  }
}
