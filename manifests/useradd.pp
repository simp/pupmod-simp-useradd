# Install and configure the useradd default configuration file.
# See useradd(8) for more details.
#
class useradd::useradd (
  # defaults in data/common.yaml
  Integer $group,
  Stdlib::AbsolutePath $home,
  Integer $inactive,
  Optional[String] $expire,
  Stdlib::AbsolutePath $shell,
  Stdlib::AbsolutePath $skel,
  Boolean $create_mail_spool
) {
  if !empty($expire) { validate_re($expire,'^\d{4}-\d{2}-\d{2}$') }

  file { '/etc/default/useradd':
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('useradd/etc/default/useradd.erb')
  }
}

