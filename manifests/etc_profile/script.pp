# @summary Write, or remove, one login script in /etc/profile.d
#
# @param content
#   The script body, or `absent` to remove the script.
#
# @param user_whitelist
#   Users the script skips.
#
# @api private
#
define useradd::etc_profile::script (
  String $content,
  Array  $user_whitelist = [],
) {
  assert_private()

  if $content == 'absent' {
    file { $title:
      ensure => 'absent',
    }
  }
  else {
    $_users = $user_whitelist.join(' ')

    $_whitelist = $user_whitelist.empty ? {
      true    => '',
      default => $title ? {
        /\.csh\z/ => "foreach user (${_users})\n  if ( \"\$user\" == \"\$USER\" ) then\n    exit\n  endif\nend\n\n",
        default   => "for user in ${_users}; do\n  if [ \"\$USER\" == \"\$user\" ]; then\n    return\n  fi\ndone\n\n",
      },
    }

    file { $title:
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      seltype => 'bin_t',
      content => "# This file managed by Puppet.\n# Any changes will be overwritten at the next run.\n\n${_whitelist}${content}\n",
    }
  }
}
