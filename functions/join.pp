# @summary Join an Array parameter's value, passing anything else through
#
# @param value
#   The parameter's value: an Array, `absent`, or `undef`.
#
# @param separator
#   What to join Array elements with.
#
# @return [Optional[String]]
#
# @api private
#
function useradd::join (
  Optional[Variant[Array, String]] $value,
  String                           $separator,
) >> Optional[String] {
  $value ? {
    Array   => $value.join($separator),
    default => $value,
  }
}
