# Manage settings in /etc/default/useradd
#
# See useradd(8) for more details. Each parameter manages the key of the same
# name, upper-cased, editing the file in place. An unset parameter leaves its
# key alone, and `absent` removes the key.
#
# @param group
# @param home
# @param inactive
# @param expire
# @param shell
# @param skel
# @param create_mail_spool
#   Written as `yes`/`no`.
#
# @param mode
#   The mode of `/etc/default/useradd`, owned by `root:root`. Leaves the mode
#   alone when unset.
#
# @param purge
#   Remove every key the class doesn't set. Comments stay. Nothing is purged
#   while no key is set.
#
# author: SIMP Team <simp@simp-project.com>
#
class useradd::useradd (
  Optional[Variant[Integer, Enum['absent']]]                        $group             = undef,
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]]           $home              = undef,
  Optional[Variant[Integer, Enum['absent']]]                        $inactive          = undef,
  Optional[Variant[Pattern[/^\d{4}-\d{2}-\d{2}$/], Enum['absent']]] $expire            = undef,
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]]           $shell             = undef,
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]]           $skel              = undef,
  Optional[Variant[Boolean, Enum['absent']]]                        $create_mail_spool = undef,
  Optional[Stdlib::Filemode]                                        $mode              = undef,
  Boolean                                                           $purge             = false,
) {
  $_settings = {
    'GROUP'             => $group,
    'HOME'              => $home,
    'INACTIVE'          => $inactive,
    'EXPIRE'            => $expire,
    'SHELL'             => $shell,
    'SKEL'              => $skel,
    'CREATE_MAIL_SPOOL' => $create_mail_spool,
  }.filter |$key, $value| { $value =~ NotUndef }

  useradd::settings { '/etc/default/useradd':
    lens     => 'Shellvars.lns',
    settings => $_settings,
    mode     => $mode,
    purge    => $purge,
  }
}
