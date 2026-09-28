# Manage settings in /etc/default/nss
#
# Read by `libnss_nis`. Each parameter manages the key of the same name,
# upper-cased, editing the file in place. An unset parameter leaves its key
# alone, and `absent` removes the key. Booleans are written as `TRUE`/`FALSE`.
#
# @param netid_authoritative
# @param services_authoritative
# @param setent_batch_read
#
# @param mode
#   The mode of `/etc/default/nss`, owned by `root:root`. Leaves the mode
#   alone when unset.
#
# @param purge
#   Remove every key the class doesn't set. Comments stay. Nothing is purged
#   while no key is set.
#
# author: SIMP Team <simp@simp-project.com>
#
class useradd::nss (
  Optional[Variant[Boolean, Enum['absent']]] $netid_authoritative    = undef,
  Optional[Variant[Boolean, Enum['absent']]] $services_authoritative = undef,
  Optional[Variant[Boolean, Enum['absent']]] $setent_batch_read      = undef,
  Optional[Stdlib::Filemode]                 $mode                   = undef,
  Boolean                                    $purge                  = false,
) {
  $_settings = {
    'NETID_AUTHORITATIVE'    => $netid_authoritative,
    'SERVICES_AUTHORITATIVE' => $services_authoritative,
    'SETENT_BATCH_READ'      => $setent_batch_read,
  }.filter |$key, $value| { $value =~ NotUndef }.map |$key, $value| {
    [$key, $value ? { true => 'TRUE', false => 'FALSE', default => $value }]
  }.convert_to(Hash)

  useradd::settings { '/etc/default/nss':
    lens     => 'Shellvars.lns',
    settings => $_settings,
    mode     => $mode,
    purge    => $purge,
  }
}
