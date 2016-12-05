# This class takes various SIMP security-related settings and
# applies them to the appropriate /etc/profile.d/simp.* files to
# enforce them at login for all users.
#
# Currently only supports csh and sh files in profile.d.
#
# @param session_timeout Integer
#   The number of *minutes* that a user may be idle prior to being
#   logged out. This is a logical extension of the SCAP Security Guide
#   requirements for Graphical and SSH timeouts and takes the place of
#   a terminal screen lock since we haven't found one that works in
#   100% of the authentication scenarios.
#
# @param umask String
#   The umask that will be applied to the user upon login.
#   Covers CCE-26917-5, CCE-27034-8, and CCE-26669-2
#
# @param mesg Boolean
#   If true, set mesg to allow writes to user terminals using wall,
#   etc...
#
# @param user_whitelist Array
#   A list of users that you don't want to be affected by these
#   settings.
#
# @param prepend Hash
#   Content that you want prepended to the settings scripts.
#   The hash takes the form 'extension' => 'content'.
#   Content will be written exactly as provided, no custom formatting
#   will be performed.
#
#   Example:
#     { 'sh' => 'if [ $UID -eq 0 ]; then echo "foo"; fi ' }
#   Result:
#     = /etc/profile.d/simp.sh =
#      if [ $UID -eq 0 ]; then echo "foo"; fi
#      <usual content>
#
# @param append Hash
#   Content that you want appended to the settings scripts.
#   See $prepend for usage.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class useradd::etc_profile (
  Integer $session_timeout = 15,
  String $umask            = '0077',
  Boolean $mesg            = false,
  Array $user_whitelist    = [],
  Hash $prepend            = {},
  Hash $append             = {}
){

  file { '/etc/profile.d/simp.sh':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    seltype => 'bin_t',
    content => template('useradd/etc/profile.d/simp.sh.erb')
  }

  file { '/etc/profile.d/simp.csh':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    seltype => 'bin_t',
    content => template('useradd/etc/profile.d/simp.csh.erb')
  }
}
