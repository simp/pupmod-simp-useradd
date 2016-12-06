# Install and configure the NSS configuration file.
# See nss(5) for more details.
#
class useradd::nss (
  # defaults in data/common.yaml
  Boolean $netid_authoritative,
  Boolean $services_authoritative,
  Boolean $setent_batch_read
) {

  file { '/etc/default/nss':
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('useradd/etc/default/nss.erb')
  }
}
