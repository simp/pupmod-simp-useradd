# @summary One entry of a one-entry-per-line file, such as `/etc/shells`
#
# Anything but whitespace, `#`, quotes and backslashes, which the augeas
# lenses and path expressions can't hold.
#
type Useradd::ListEntry = Pattern[/\A[^\s#'"\\]+\z/]
