skips = {
  'V-72001' => 'Skipping: Enforced via pupmod-simp-deferred_resources, not pupmod-simp-useradd.',
  'V-72059' => 'Skipping: Vagrant base boxes do not have separate mount points defined for /home.',
  'V-73167' => 'Skipping: Auditing controls are handled with pupmod-simp-auditd.',
  'V-73173' => 'Skipping: Auditing controls are handled with pupmod-simp-auditd.'
}
overrides = [
  'V-71927',
  'V-72223'
]
subsystems = [ 'libuser_conf', 'user', '/etc/shadow', 'accounts', 'opasswd', 
'home_dirs', 'user_profile', 'login_defs', 'gshadow' ]

require_controls 'disa_stig-el7-baseline' do
  skips.each_pair do |ctrl, reason|
    control ctrl do
      describe "Skip #{ctrl}" do
        skip "Reason: #{skips[ctrl]}" do
        end
      end
    end
  end

  @conf['profile'].info[:controls].each do |ctrl|
    next if (overrides + skips.keys).include?(ctrl[:id])

    tags = ctrl[:tags]
    if tags && tags[:subsystems]
      subsystems.each do |subsystem|
        if tags[:subsystems].include?(subsystem)
          control ctrl[:id]
        end
      end
    end
  end

  ## Overrides ##

  # The current check does not account for `nfsnobody` user
  # Filed SIMP-8333
  control 'V-71927' do
    overrides << self.to_s

    shadow.users.each do |user|
      # filtering on non-system accounts (uid >= 1000)
      next unless user(user).uid >= 1000
      next if user == 'nfsnobody'
      describe shadow.users(user) do
        its('min_days.first.to_i') { should cmp >= 1 }
      end
    end
  end

  # The current environment value check has a type mismatch
  # Filed SIMP-8334
  control 'V-72223' do
    overrides << self.to_s

    describe os_env('TMOUT') do
      its('content') { should be <= "600" }
    end

    # Check if TMOUT is set in files (passive test)
    files = ['/etc/bashrc'] + ['/etc/profile'] + command("find /etc/profile.d/*").stdout.split("\n")
    latest_val = nil

    files.each do |file|
      readonly = false

      # Skip to next file if TMOUT isn't present. Otherwise, get the last occurrence of TMOUT
      next if (values = command("grep -Po '.*TMOUT.*' #{file}").stdout.split("\n")).empty?

      # Loop through each TMOUT match and see if set TMOUT's value or makes it readonly
      values.each_with_index { |value, index|

        # Skip if starts with '#' - it represents a comment
        next if !value.match(/^#/).nil?
        # If readonly and value is inline - use that value
        if !value.match(/^readonly[\s]+TMOUT[\s]*=[\s]*[\d]+$/).nil?
          latest_val = value.match(/[\d]+/)[0].to_i
          readonly = true
          break
        # If readonly, but, value is not inline - use the most recent value
        elsif !value.match(/^readonly[\s]+([\w]+[\s]+)?TMOUT[\s]*([\s]+[\w]+[\s]*)*$/).nil?
          # If the index is greater than 0, the configuraiton setting value.
          # Otherwise, the configuration setting value is in the previous file
          # and is already set in latest_val.
          if index >= 1
            latest_val = values[index - 1].match(/[\d]+/)[0].to_i
          end
          readonly = true
          break
        # Readonly is not set use the lastest value
        else
          latest_val = value.match(/[\d]+/)[0].to_i
        end
      }
      # Readonly is set - stop processing files
      break if readonly === true
    end

    if latest_val.nil?
      describe "The TMOUT setting is configured" do
        subject { !latest_val.nil? }
        it { should be true }
      end
    else
      describe"The TMOUT setting is configured properly" do
        subject { latest_val }
        it { should be <= 600 }
      end
    end
  end
end
