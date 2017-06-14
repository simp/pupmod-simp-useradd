# Manage the persmissions of shadow and passwd related files
#
# author: SIMP Team <simp@simp-project.com>
#
class useradd::passwd {

  # CCE-26953-0
  # CCE-26856-5
  # CCE-26868-0
  file { [
    '/etc/passwd',
    '/etc/passwd-'
  ]:
    owner => 'root',
    group => 'root',
    mode  => '0644'
  }

  # CCE-26947-2
  # CCE-26967-0
  # CCE-26992-8
  # CCE-27026-4
  # CCE-26975-3
  # CCE-26951-4
  file { [
    '/etc/shadow',
    '/etc/shadow-',
    '/etc/gshadow',
    '/etc/gshadow-'
  ]:
    owner => 'root',
    group => 'root',
    mode  => '0000'
  }

  # CCE-26822-7
  # CCE-26930-8
  # CCE-26954-8
  file { [
    '/etc/group',
    '/etc/group-'
  ]:
    owner => 'root',
    group => 'root',
    mode  => '0644'
  }

  file { '/etc/security/opasswd':
    owner => 'root',
    group => 'root',
    mode  => '0600'
  }

}
