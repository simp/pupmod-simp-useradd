# UseraddTestUtil namespace
module UseraddTestUtil
  # Files a bare `include useradd` must leave exactly as they were.
  WATCHED_FILES = [
    '/etc/login.defs', '/etc/default/useradd', '/etc/libuser.conf',
    '/etc/securetty', '/etc/shells', '/etc/passwd', '/etc/passwd-',
    '/etc/shadow', '/etc/shadow-', '/etc/group', '/etc/group-',
    '/etc/gshadow', '/etc/gshadow-', '/etc/default/nss', '/etc/sysconfig/init'
  ].freeze

  # Checksums, modes and owners of WATCHED_FILES, plus the contents of the
  # directories the module can write into. Missing files are reported as such.
  STATE_CMD = [
    "for f in #{WATCHED_FILES.join(' ')}; do",
    '  if [ -e "$f" ]; then echo "$(sha256sum "$f" | cut -d" " -f1) $(stat -c "%a %U %G" "$f") $f"; else echo "missing $f"; fi;',
    'done;',
    'ls -la /etc/profile.d /etc/systemd/system/emergency.service.d /etc/systemd/system/rescue.service.d 2>&1; true',
  ].join(' ').freeze

  # Include in a describe block to get #with_simp_defaults_enforced.
  module ComplianceEngine
    # Runs the block with `compliance_engine::enforcement: [simp:defaults]` in
    # force, plus any extra hieradata, then puts the environment's hiera.yaml
    # back. The Compliance Engine layer goes last, so it has the lowest
    # priority, as it does at a real site. The hieradata written here is
    # replaced by the next set_hieradata_on call.
    def with_simp_defaults_enforced(host, hieradata = {})
      original = get_hiera_config_on(host)
      config = YAML.safe_load(original)
      config['hierarchy'] << {
        'name'       => 'Compliance Engine',
        'lookup_key' => 'compliance_engine::enforcement',
      }
      set_hiera_config_on(host, config)
      set_hieradata_on(host, { 'compliance_engine::enforcement' => ['simp:defaults'] }.merge(hieradata))

      yield
    ensure
      set_hiera_config_on(host, original) if original
    end
  end
end
