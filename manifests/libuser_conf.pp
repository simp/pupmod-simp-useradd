# Manage settings in /etc/libuser.conf
#
# See libuser.conf(5) for information on the various variables. Each parameter
# manages one key, editing the file in place: `defaults_*` the `[defaults]`
# section, `files_*` the `[files]` section, and so on. An unset parameter
# leaves its key alone, and `absent` removes the key. Booleans are written as
# `yes`/`no`.
#
# With both `defaults_modules` and `defaults_create_modules` set, as in 3.x,
# the `files_*`, `shadow_*` and `ldap_*` keys are written only when their
# section is in `defaults_create_modules` and not in `defaults_modules`.
#
# @param defaults_modules
#   Joined with `,`. `[]` removes the key.
# @param defaults_create_modules
#   Joined with `,`. `[]` removes the key.
# @param defaults_crypt_style
# @param defaults_hash_rounds_min
# @param defaults_hash_rounds_max
# @param defaults_mailspooldir
# @param defaults_moduledir
# @param defaults_skeleton
# @param import_login_defs
# @param import_default_useradd
# @param userdefaults_settings
#   Keys of the `[userdefaults]` section, mapped to their values. `absent`
#   removes a key.
# @param groupdefaults_settings
#   Keys of the `[groupdefaults]` section, mapped to their values. `absent`
#   removes a key.
# @param userdefaults
#   Deprecated: use `userdefaults_settings`. As in 3.x, `KEY = value` lines
#   that make up the whole `[userdefaults]` section: other keys in it are
#   removed, and `userdefaults_settings` is ignored.
# @param groupdefaults
#   Deprecated: use `groupdefaults_settings`. As in 3.x, `KEY = value` lines
#   that make up the whole `[groupdefaults]` section: other keys in it are
#   removed, and `groupdefaults_settings` is ignored.
# @param files_directory
# @param files_nonroot
# @param shadow_directory
# @param shadow_nonroot
# @param ldap_userbranch
# @param ldap_groupbranch
# @param ldap_server
# @param ldap_basedn
# @param ldap_binddn
# @param ldap_user
# @param ldap_password
# @param ldap_authuser
# @param ldap_bindtype
# @param sasl_appname
# @param sasl_domain
#
# @param mode
#   The mode of `/etc/libuser.conf`, owned by `root:root`. Leaves the mode
#   alone when unset.
#
# @param purge
#   Remove every key the class doesn't set, in every section. Comments stay.
#   Nothing is purged while no key is set.
#
# author: SIMP Team <simp@simp-project.com>
#
class useradd::libuser_conf (
  Optional[Variant[Array[Useradd::LibuserModule], Enum['absent']]] $defaults_modules         = undef,
  Optional[Variant[Array[Useradd::LibuserModule], Enum['absent']]] $defaults_create_modules  = undef,
  Optional[Variant[Useradd::CryptStyle, Enum['absent']]]           $defaults_crypt_style     = undef,
  Optional[Variant[Integer[1000,999999999], Enum['absent']]]       $defaults_hash_rounds_min = undef,
  Optional[Variant[Integer[1000,999999999], Enum['absent']]]       $defaults_hash_rounds_max = undef,
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]]          $defaults_mailspooldir    = undef,
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]]          $defaults_moduledir       = undef,
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]]          $defaults_skeleton        = undef,
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]]          $import_login_defs        = undef,
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]]          $import_default_useradd   = undef,
  Hash[Pattern[/\A[A-Za-z0-9_]+\z/], Variant[String[1], Integer]]  $userdefaults_settings    = {},
  Hash[Pattern[/\A[A-Za-z0-9_]+\z/], Variant[String[1], Integer]]  $groupdefaults_settings   = {},
  Optional[String]                                                 $userdefaults             = undef,
  Optional[String]                                                 $groupdefaults            = undef,
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]]          $files_directory          = undef,
  Optional[Variant[Boolean, Enum['absent']]]                       $files_nonroot            = undef,
  Optional[Variant[Stdlib::AbsolutePath, Enum['absent']]]          $shadow_directory         = undef,
  Optional[Variant[Boolean, Enum['absent']]]                       $shadow_nonroot           = undef,
  Optional[String]                                                 $ldap_userbranch          = undef,
  Optional[String]                                                 $ldap_groupbranch         = undef,
  Optional[String]                                                 $ldap_server              = undef,
  Optional[String]                                                 $ldap_basedn              = undef,
  Optional[String]                                                 $ldap_binddn              = undef,
  Optional[String]                                                 $ldap_user                = undef,
  Optional[String]                                                 $ldap_password            = undef,
  Optional[String]                                                 $ldap_authuser            = undef,
  Optional[String]                                                 $ldap_bindtype            = undef,
  Optional[String]                                                 $sasl_appname             = undef,
  Optional[String]                                                 $sasl_domain              = undef,
  Optional[Stdlib::Filemode]                                       $mode                     = undef,
  Boolean                                                          $purge                    = false,
) {
  if ($defaults_hash_rounds_min =~ Integer and $defaults_hash_rounds_max =~ Integer) {
    if ($defaults_hash_rounds_min >= $defaults_hash_rounds_max) {
      fail('$defaults_hash_rounds_min must be less than $defaults_hash_rounds_max')
    }
  }

  # `[]` removes the key; libuser treats an empty list as unset.
  $_modules = $defaults_modules ? {
    []      => 'absent',
    default => useradd::join($defaults_modules, ','),
  }
  $_create_modules = $defaults_create_modules ? {
    []      => 'absent',
    default => useradd::join($defaults_create_modules, ','),
  }

  # Deprecated: the 3.x Strings, parsed into the whole section's keys.
  $_legacy = {
    'userdefaults'  => $userdefaults,
    'groupdefaults' => $groupdefaults,
  }.filter |$section, $lines| { $lines =~ NotUndef }.map |$section, $lines| {
    deprecation("useradd::libuser_conf::${section}", "useradd::libuser_conf::${section} is deprecated and will be removed in a future release. Use useradd::libuser_conf::${section}_settings instead.", false)

    $_keys = $lines.split("\n").map |$line| { $line.strip }.filter |$line| { $line =~ /\A[^#;]/ }.reduce({}) |$keys, $line| {
      $_match = $line.match(/\A([A-Za-z0-9_]+)\s*=\s*(.*)\z/)
      unless $_match {
        fail("useradd::libuser_conf::${section}: '${line}' is not a KEY = value line")
      }
      $keys + { $_match[1] => $_match[2] }
    }
    [$section, $_keys]
  }.convert_to(Hash)

  # A deprecated String replaces its Hash.
  $_free_form = {
    'userdefaults'  => $userdefaults_settings,
    'groupdefaults' => $groupdefaults_settings,
  }.reduce({}) |$memo, $section| {
    $_keys = $_legacy[$section[0]] ? {
      undef   => $section[1],
      default => $_legacy[$section[0]],
    }
    $memo + $_keys.reduce({}) |$keys, $kv| { $keys + { "${section[0]}/${kv[0]}" => $kv[1] } }
  }

  $_settings = {
    'import/login_defs'       => $import_login_defs,
    'import/default_useradd'  => $import_default_useradd,
    'defaults/modules'        => $_modules,
    'defaults/create_modules' => $_create_modules,
    'defaults/crypt_style'    => $defaults_crypt_style,
    'defaults/hash_rounds_min' => $defaults_hash_rounds_min,
    'defaults/hash_rounds_max' => $defaults_hash_rounds_max,
    'defaults/mailspooldir'   => $defaults_mailspooldir,
    'defaults/moduledir'      => $defaults_moduledir,
    'defaults/skeleton'       => $defaults_skeleton,
    'files/directory'         => $files_directory,
    'files/nonroot'           => $files_nonroot,
    'shadow/directory'        => $shadow_directory,
    'shadow/nonroot'          => $shadow_nonroot,
    'ldap/userBranch'         => $ldap_userbranch,
    'ldap/groupBranch'        => $ldap_groupbranch,
    'ldap/server'             => $ldap_server,
    'ldap/basedn'             => $ldap_basedn,
    'ldap/binddn'             => $ldap_binddn,
    'ldap/user'               => $ldap_user,
    'ldap/password'           => $ldap_password,
    'ldap/authuser'           => $ldap_authuser,
    'ldap/bindtype'           => $ldap_bindtype,
    'sasl/appname'            => $sasl_appname,
    'sasl/domain'             => $sasl_domain,
  }.filter |$key, $value| {
    $_section = $key.split('/')[0]
    # 3.x wrote a module's section only for a module used to create new
    # entries but not otherwise.
    $value =~ NotUndef and !(
      $_section in ['files', 'shadow', 'ldap'] and
      $defaults_modules =~ Array and $defaults_create_modules =~ Array and
      !($_section in $defaults_create_modules and !($_section in $defaults_modules))
    )
  } + $_free_form

  useradd::settings { '/etc/libuser.conf':
    lens     => 'Puppet.lns',
    settings => $_settings,
    mode     => $mode,
    purge    => $purge,
    sections => true,
  }

  $_mode_file = $mode ? {
    undef   => undef,
    default => File['/etc/libuser.conf'],
  }

  # A deprecated String is the whole section, as in 3.x: every other key in it
  # is removed.
  $_legacy.each |$section, $keys| {
    $_path = "${section}/*[label() != '#comment'${keys.keys.map |$k| { " and label() != '${k}'" }.join}]"

    augeas { "/etc/libuser.conf ${section}":
      incl    => '/etc/libuser.conf',
      lens    => 'Puppet.lns',
      context => '/files/etc/libuser.conf',
      changes => "rm ${_path}",
      onlyif  => "match ${_path} size > 0",
      before  => $_mode_file,
    }
  }
}
