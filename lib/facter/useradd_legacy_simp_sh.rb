# frozen_string_literal: true

# Whether `/etc/profile.d/simp.sh` or `simp.csh`, the login scripts written by
# useradd 3.x, is present.
#
# Only used to warn that `prepend` and `append` content may run twice at login.
Facter.add('useradd_legacy_simp_sh') do
  confine kernel: 'Linux'

  setcode do
    ['/etc/profile.d/simp.sh', '/etc/profile.d/simp.csh'].any? { |path| File.exist?(path) }
  end
end
