# Deprecated: no longer manages `/etc/default/nss`
#
# Nothing on EL8 or later reads `/etc/default/nss`. The parameters are kept so
# existing Hiera data still compiles, and warn when set.
#
# @param netid_authoritative
#   Deprecated: ignored.
#
# @param services_authoritative
#   Deprecated: ignored.
#
# @param setent_batch_read
#   Deprecated: ignored.
#
# author: SIMP Team <simp@simp-project.com>
#
class useradd::nss (
  Optional[Boolean] $netid_authoritative    = undef,
  Optional[Boolean] $services_authoritative = undef,
  Optional[Boolean] $setent_batch_read      = undef,
) {
  ['netid_authoritative', 'services_authoritative', 'setent_batch_read'].each |$param| {
    if getvar($param) =~ NotUndef {
      deprecation("useradd::nss::${param}", "useradd::nss::${param} is deprecated and ignored: nothing on EL8 or later reads /etc/default/nss.", false)
    }
  }
}
