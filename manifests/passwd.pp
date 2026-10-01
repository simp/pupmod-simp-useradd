# Manage the ownership and permissions of shadow and passwd related files
#
# @param files
#   Files mapped to the `owner`, `group` and `mode` to enforce. Only the
#   attributes given are managed, and a missing file is not created.
#
#   The `simp:defaults` compliance profile restores the useradd 3.x settings:
#   `root:root` for every file, `0644` for `/etc/passwd` and `/etc/group`, and
#   `0000` for `/etc/shadow` and `/etc/gshadow`, each with its `-` backup.
#   These cover CCE-26953-0, CCE-26856-5, CCE-26868-0, CCE-26947-2,
#   CCE-26967-0, CCE-26992-8, CCE-27026-4, CCE-26975-3, CCE-26951-4,
#   CCE-26822-7, CCE-26930-8 and CCE-26954-8.
#
# author: SIMP Team <simp@simp-project.com>
#
class useradd::passwd (
  Hash[
    Stdlib::AbsolutePath,
    Struct[{
      Optional[owner] => String[1],
      Optional[group] => String[1],
      Optional[mode]  => Stdlib::Filemode,
    }]
  ] $files = {},
) {
  $files.each |$path, $attributes| {
    file { $path:
      * => $attributes,
    }
  }
}
