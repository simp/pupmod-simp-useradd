# Install and configure the NSS configuration file.
# See nss(5) for more details.
#
# @param netid_authoritative
# @param services_authoritative
# @param setent_batch_read
#
# author: SIMP Team <simp@simp-project.com>
#
class useradd::nss (
  Boolean $netid_authoritative    = false,
  Boolean $services_authoritative = false,
  Boolean $setent_batch_read      = true,
) {

  file { '/etc/default/nss':
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('useradd/etc/default/nss.erb')
  }
}
