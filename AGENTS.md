# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this module does

`simp-useradd` is a SIMP Puppet module that manages **system-wide user-account
creation defaults and login policy files**. It does **not** create or manage
individual user accounts. It edits `/etc/login.defs`, `/etc/default/useradd`,
`/etc/libuser.conf`, `/etc/securetty`, `/etc/shells`, login scripts in
`/etc/profile.d`, the permissions of the passwd/shadow/group files, and the
systemd emergency/rescue drop-ins.

### A bare include manages nothing (4.0.0)

Since 4.0.0, `include useradd` declares no File, Augeas or Exec resource.
Every setting is managed only when its parameter is set, with three states:

- `undef` (the default): left alone;
- a value: set, replacing the old value;
- `'absent'` (or `false` for a Boolean): removed.

Lists are `*_entries` Hashes of entry → `Useradd::EntryOptions`, merged `deep`
(`data/common.yaml`). Purging unmanaged keys or entries is opt-in through
`purge*` parameters.

The 3.x behavior comes back through the shipped `simp:defaults` compliance
profile (`SIMP/compliance_profiles/`), enforced with
`compliance_engine::enforcement: [simp:defaults]`. The profile sets no
deprecated parameter and no UID/GID range.

### Business logic

`useradd` (`manifests/init.pp`) includes seven component classes, each owning
one file or group of files. It also edits `/etc/securetty` and `/etc/shells`
itself.

- **`useradd`** — `securetty_entries`, `shells_entries`, `purge_securetty`,
  `purge_shells`, `securetty_mode`, `shells_mode`. Entries map to
  `Useradd::EntryOptions` (`{}` = present), applied by the private
  `useradd::entry::list`. The deprecated `securetty`, `shells_default` and
  `shells` keep their 3.x behavior: set, each owns its whole file (3.x modes
  `0400`/`0644`) and the matching `*_entries`/`purge_*` are ignored.
  The deprecated `manage_*` Booleans still skip a class when `false`.
- **`useradd::login_defs`** — per-key augeas (`Login_defs.lns`), `mode`,
  `purge`. The purge always keeps `UID_MIN`, `UID_MAX`, `GID_MIN` and
  `GID_MAX`. An empty value is deprecated and skipped: the lens can't parse a
  key with no value.
- **`useradd::useradd`** — `/etc/default/useradd`, per-key augeas
  (`Shellvars.lns`), `mode`, `purge`.
- **`useradd::libuser_conf`** — `/etc/libuser.conf`, per-key augeas
  (`Puppet.lns`, keys as `section/key`), `mode`, `purge`. Fails compilation
  if `defaults_hash_rounds_min >= defaults_hash_rounds_max`. With both
  module lists set, `[files]`/`[shadow]`/`[ldap]` keys are written only for a
  module in `defaults_create_modules` and not in `defaults_modules`, as in 3.x.
- **`useradd::passwd`** — manages only the files listed in
  `useradd::passwd::files` (Hash of path → owner/group/mode).
- **`useradd::etc_profile`** — one `/etc/profile.d` file per setting via
  `useradd::etc_profile::script` (`simp-b-tmout.sh`, `zz-simp-umask.sh`,
  ...). `legacy_simp_sh: true` writes the 3.x `simp.sh`/`simp.csh` from the
  templates, with `prepend`/`append` inside them as in 3.x; `false` removes
  them.
- **`useradd::sysconfig_init`** — `/etc/sysconfig/init`, per-key augeas
  (`Shellvars.lns`), `mode`, `purge`; plus the emergency/rescue drop-ins when
  `single_user_login` is set on systemd hosts, with a refresh-only
  `daemon-reload` exec. Includes `systemd` only when `systemd => true`.
- **`useradd::nss`** — `/etc/default/nss`, per-key augeas (`Shellvars.lns`),
  `mode`, `purge`.

### Shared building blocks

- `useradd::setting` / `useradd::settings` — set or remove one key (or a
  Hash of keys) with augeas, with explicit `incl`, `lens` and `context`.
- `useradd::purge` — remove every key except the listed ones.
- `useradd::entry` / `useradd::entry::purge` — the same for
  one-entry-per-line files (securetty, shells).
- `useradd::join` — joins Array values (e.g. `CONSOLE` with `:`).
- Fact `useradd_legacy_simp_sh` (`lib/facter/`) — true when the 3.x
  `simp.sh`/`simp.csh` are still present; drives a warning when
  `prepend`/`append` would run twice.

## Gotchas / non-obvious details

- **This module does not manage user accounts.**
- **Never add a default that writes a value.** A new parameter defaults to
  `undef`; restore any 3.x value in `SIMP/compliance_profiles/checks.yaml`.
- **Check IDs use dots:** `simp:defaults.useradd.login_defs.umask`.
  `spec/classes/useradd_simp_defaults_profile_spec.rb` enforces the naming,
  that every check's parameter exists, and that no deprecated parameter is
  set.
- **The deprecated Arrays keep their 3.x types**, so `shells`
  (`Array[Stdlib::AbsolutePath]`) can't take a `--` knockout. Use
  `shells_entries`.
- **Deprecations use `deprecation(key, msg, false)`**, which never fails
  compilation under `strict=error`. Don't use `warning()` for them. The
  third argument needs stdlib 9.2.0.
- **The drop-in directories are declared with `ensure_resource`** and the
  same attributes as `systemd::dropin_file`, so both can declare them. Keep
  them in sync with puppet/systemd.
- **A type alias can't share a define's name.** `Useradd::Entry` would
  resolve to the `useradd::entry` resource type, hence `Useradd::ListEntry`.
- **`useradd::setting` escapes only `"`.** The augeas provider passes `\x`
  through verbatim, so a value with a backslash before `"` or at the end
  fails compilation.
- **`pass_min_len` / `pass_max_len`** have no effect on stock EL; minimum
  length is set via PAM / `pwquality.conf`.
- **`etc_profile::manage_tmout`** is deprecated; leave `session_timeout`
  unset instead.

## The `simp_options` / `simplib::lookup` seam

The UID/GID ranges in `manifests/login_defs.pp` default to
`simplib::lookup('simp_options::{uid,gid}::{min,max}', { 'default_value' => undef })`.
Unset, nothing is written. The profile deliberately doesn't set them.
`simp/simp_options` is not a declared dependency.

## Dependencies

Module dependencies (from `metadata.json`):

- `simp/simplib` `>= 4.9.0 < 8.0.0` — provides `simplib::lookup` and the
  `Simplib::Umask` type.
- `puppetlabs/stdlib` `>= 9.2.0 < 11.0.0` — provides `Stdlib::AbsolutePath`,
  `Stdlib::Filemode`, `pick()`, and the 3-argument `deprecation()`.
- `puppet/systemd` `>= 4.0.2 < 11.0.0` — the `systemd` class, included only
  when `useradd::sysconfig_init::systemd` is true.

There are **no optional dependencies** (`metadata.json` has no
`simp.optional_dependencies` block) and no `simplib::assert_optional_dependency`
calls anywhere in the manifests.

Runtime requirement (from `metadata.json`): `openvox >= 8.0.0 < 9.0.0`.
This module has migrated its runtime baseline from Puppet to **OpenVox** — the
`requirements` entry names `openvox`, not `puppet`.

Supported OS matrix (from `metadata.json`): CentOS 9/10; RedHat 8/9/10;
OracleLinux 8/9/10; Rocky 8/9/10; AlmaLinux 8/9/10.

## Repository layout

- `manifests/` — the eight classes above, plus the `useradd::setting`,
  `settings`, `purge`, `entry`, `entry::list`, `entry::purge` and `etc_profile::script`
  defines.
- `functions/` — `useradd::join`.
- `types/` — `Useradd::Bootup`, `Useradd::CryptStyle`, `Useradd::EntryOptions`,
  `Useradd::LibuserModule`, `Useradd::ListEntry`, `Useradd::Tty`.
- `data/common.yaml` + `hiera.yaml` — `lookup_options` (deep merge for the
  `*_entries` and `passwd::files` Hashes). No default values.
- `lib/facter/useradd_legacy_simp_sh.rb` — the legacy-script fact.
- `templates/etc/profile.d/simp.{sh,csh}.erb` — used only with
  `legacy_simp_sh: true`.
- `SIMP/compliance_profiles/` — the `simp:defaults` profile and checks.
- `spec/classes/` — unit specs; `spec/fixtures/hieradata/` holds the
  compliance-engine Hiera fixtures.
- `spec/acceptance/suites/default/00_default_spec.rb` — the beaker suite
  (noop preview, bare include, single-setting enforce/un-enforce/absent,
  `simp:defaults` convergence).
- `REFERENCE.md` — generated Puppet Strings reference.

### CI

`.github/workflows/pr_tests.yml` (puppetsync-managed) runs six standard jobs —
`puppet-syntax`, `puppet-style` (`rake lint` + `rake metadata_lint`),
`ruby-style` (`rake rubocop`, `continue-on-error`), `file-checks`,
`releng-checks` (version/tag/changelog + `pdk build --force`), and `spec-tests`
(`rake parallel_spec` on Puppet 8.x) — **plus an active `acceptance` job**.

The `acceptance` job is **podman/docker-based** (not vagrant): it runs on
`ubuntu-latest`, starts the rootless podman socket and exports
`DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock`
(`pr_tests.yml`), then runs
`bundle exec rake beaker:suites[default,<node>]` (`pr_tests.yml`).

The active matrix is 11 container nodes (`pr_tests.yml`):
`docker_almalinux8/9/10`, `docker_centos9/10`, `docker_oel8/9/10`,
`docker_rocky8/9/10`.

**Gotcha:** the three `docker_rhel8/9/10` rows are **commented out**
(`pr_tests.yml`) — the workflow explains RHEL UBI containers cannot
install packages without a subscription, so RHEL is intentionally excluded from
active CI. There are **29 nodeset files** in `spec/acceptance/nodesets/`
(including the disabled `rhel*`/`docker_rhel*` and non-docker `vagrant`-style
entries); only the 11 above are exercised by CI.

## Common commands

```sh
# Install dependencies
bundle install

# Run all unit tests
bundle exec rake spec

# Run unit tests in parallel (as CI does)
bundle exec rake parallel_spec

# Puppet lint + metadata lint
bundle exec rake lint
bundle exec rake metadata_lint

# Ruby lint
bundle exec rake rubocop

# Test-build the module (as the RELENG CI job does)
bundle exec pdk build --force

# Regenerate REFERENCE.md from puppet-strings docstrings
puppet strings generate --format markdown --out REFERENCE.md

# Run the default beaker acceptance suite against one container node
bundle exec rake beaker:suites[default,docker_almalinux9]
```

Relevant gem pins (from `Gemfile`): `rubocop ~> 1.88.0` (`Gemfile`),
`puppetlabs_spec_helper ~> 8.0.0` (`Gemfile`),
`simp-rake-helpers ~> 5.24.0` (`Gemfile`),
`simp-beaker-helpers ~> 2.0.0` (`Gemfile`). The default Puppet/OpenVox test
range is `['>= 8', '< 9']` (`Gemfile`). **Transitional shim:** the test group
installs **both** the `openvox` and `puppet` gems —
`['openvox', 'puppet'].each do |gem_name|` (`Gemfile`) — "until the puppet
dependency is removed from other gems."

## Conventions

- Preserve the `@summary` / `@param` puppet-strings docstrings; regenerate
  `REFERENCE.md` after changing docs or parameters.
- New settings: an `Optional[...]` parameter defaulting to `undef`, edited in
  place with `useradd::setting`, plus a check in
  `SIMP/compliance_profiles/checks.yaml` if 3.x wrote it. Never a `manage_*`
  toggle.
- Constrain parameters with the `Useradd::*`, `Stdlib::*` or `Simplib::*`
  types rather than bare `String`.
- `Gemfile`, `spec/spec_helper.rb`, and `.github/workflows/pr_tests.yml` carry a
  **puppetsync** notice — the next sync overwrites local edits. The Gemfile's
  `observer` gem (needed by compliance_engine on Ruby 3.4) must also go to
  the baseline.
- Match the existing 2-space Puppet indentation and aligned-arrow /
  aligned-parameter style used throughout `manifests/`.
