# The  algorithm to use for password encryption when creating new passwords
type Useradd::CryptStyle = Enum[
  'BLOWFISH',
  'DES',
  'MD5',
  'SHA256',
  'SHA512',
  'blowfish',
  'des',
  'md5',
  'sha256',
  'sha512'
]
