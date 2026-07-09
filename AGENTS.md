# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this module does

`simp-useradd` is a SIMP Puppet module that manages **system-wide user-account
creation defaults and login policy files** — it does **not** create or manage
individual user accounts. Instead it owns the config files that dictate how
accounts get created and how logins behave: `/etc/login.defs`,
`/etc/default/useradd`, `/etc/libuser.conf`, `/etc/default/nss`,
`/etc/sysconfig/init`, the `/etc/profile.d/simp.{sh,csh}` login fragments, and
the permissions of the passwd/shadow/group files. Many defaults carry inline
`CCE-*` benchmark IDs, so this is primarily a hardening/compliance module.

### Business logic

`useradd` is a class collection: a single orchestrator (`useradd`) that
conditionally `include`s seven component classes, each of which owns one config
file. There are no defines. **No class is `assert_private()`'d** — the component
classes are technically includable directly, but the intended entry point is
`include useradd`.

- **`useradd` (`manifests/init.pp`)** — Orchestrator. Seven
  `manage_*` Boolean toggles (all default `true`,
  `init.pp`) gate the `include` of each component class
  (`init.pp`). It also directly manages two files of its own:
  - `/etc/securetty` (`init.pp`), driven by `$securetty`
    (`Variant[Boolean,Array[String]]`, default
    `['tty0'..'tty4']`). **Tri-state, non-obvious** — see Gotchas.
  - `/etc/shells` (`init.pp`), the union of `$shells_default` +
    `$shells`, written only when `$shells` is truthy and the combined list is
    non-empty.
- **`useradd::login_defs` (`manifests/login_defs.pp`)** — Manages
  `/etc/login.defs` from `templates/etc/login_defs.erb` (mode `$mode`, default
  `0640`, `login_defs.pp`). This is the biggest class (~65
  parameters): password aging (`pass_max_days` 180, `pass_min_days` 1,
  `pass_warn_age` 14, `pass_min_len` 15 — all CCE-tagged), crypt settings
  (`encrypt_method` `SHA512`, `sha_crypt_min/max_rounds`), UID/GID ranges, umask
  (`007`, CCE-26371-5), and login/tty behavior. **The UID/GID range parameters
  are the module's `simp_options` seam — see the table below.**
- **`useradd::useradd` (`manifests/useradd.pp`)** — Manages
  `/etc/default/useradd` (mode `0600`) from `templates/etc/default/useradd.erb`.
  Defaults for new accounts: `group` 100, `home` `/home`, `inactive` 35,
  `shell` `/bin/bash`, `skel` `/etc/skel`, `create_mail_spool` true.
- **`useradd::libuser_conf` (`manifests/libuser_conf.pp`)** — Manages
  `/etc/libuser.conf` (mode `0644`) from `templates/etc/libuser.conf.erb`.
  Default crypt style `sha512` (`Useradd::CryptStyle`), modules
  `['files','shadow']` (`Useradd::LibuserModule`). **Guard:** fails compilation
  if `defaults_hash_rounds_min >= defaults_hash_rounds_max` when both are set
  (`libuser_conf.pp`).
- **`useradd::nss` (`manifests/nss.pp`)** — Manages `/etc/default/nss`
  (mode `0640`) from `templates/etc/default/nss.erb`. Three Booleans:
  `netid_authoritative` false, `services_authoritative` false,
  `setent_batch_read` true.
- **`useradd::passwd` (`manifests/passwd.pp`)** — **Parameterless.**
  Enforces ownership/permissions on the passwd/shadow/group family: `passwd`,
  `passwd-`, `group`, `group-` → `root:root 0644`; `shadow`, `shadow-`,
  `gshadow`, `gshadow-` → `root:root 0000`. Numerous CCE IDs in comments.
- **`useradd::etc_profile` (`manifests/etc_profile.pp`)** — Manages
  `/etc/profile.d/simp.sh` and `simp.csh` (mode `0644`, `seltype => bin_t`) from
  the matching `.erb` templates. Enforces an idle-session timeout
  (`session_timeout` 15 minutes, gated by `manage_tmout`) and a login umask
  (`0077`, covers CCE-26917-5/27034-8/26669-2). Supports per-shell `prepend` /
  `append` content hashes and a `user_whitelist`.
- **`useradd::sysconfig_init` (`manifests/sysconfig_init.pp`)** — Manages
  `/etc/sysconfig/init` (mode `0644`) from `templates/etc/sysconfig/init.erb`
  (bootup mode via `Useradd::Bootup`, console colors, `loglvl`, etc.).
  **Also** — on systemd hosts (`'systemd' in $facts['init_systems']`,
  `sysconfig_init.pp`) — writes `emergency.service` and `rescue.service`
  drop-ins via `systemd::dropin_file` so single-user/emergency mode requires the
  root password (`$single_user_login`, default `/sbin/sulogin`). This is why
  `puppet/systemd` is a runtime dependency.

## Gotchas / non-obvious details

- **This module does not manage user accounts.** It manages the *defaults and
  policy* that govern account creation and login. If you need to create a user,
  this is the wrong module.
- **`$securetty` is tri-state** (`init.pp`):
  - `false` → management of `/etc/securetty` is disabled entirely.
  - `true` or an empty array (the default is a populated array) → root cannot
    log in on any physical console.
  - an array containing the literal string `'ANY_SHELL'` → `/etc/securetty` is
    **removed** (`ensure => absent`), allowing root login from anywhere.
  - otherwise the array is written verbatim, one tty per line.
- **`/etc/shells` is only written when `$shells` is truthy** (`init.pp`);
  with the default `$shells = []` (falsey-for-this-guard because the guard also
  requires a non-empty combined list) the file is not managed. `$shells` also
  accepts `false` to disable management explicitly.
- **UID/GID range defaults use a fact-then-fallback pattern**, not a static
  literal:
  `pick(fact('login_defs.<key>'), <literal>)` inside the `simp_options` lookup
  default (`login_defs.pp`). The live system value (from the
  `login_defs` fact provided by `simp/simplib`) wins over the hard-coded
  fallback.
- **`useradd::sysconfig_init` reaches beyond its named file** — it also writes
  systemd `emergency`/`rescue` service drop-ins on systemd hosts
  (`sysconfig_init.pp`). Editing this class can affect single-user-mode
  authentication, not just `/etc/sysconfig/init`.
- **`login_defs` note in the docstring** (`login_defs.pp`): `pass_min_len`
  / `pass_max_len` have no effect on a stock RedHat machine — min length must be
  set via PAM / `pwquality.conf`. Don't expect these params to enforce anything
  on modern EL.
- **`etc_profile::manage_tmout`** exists specifically to avoid a `TMOUT:
  readonly variable` login warning when another `/etc/profile.d` file already
  marks `TMOUT` read-only (`etc_profile.pp`). Set it `false` in that case.
- **Manifests still use leading-`::` namespaced includes** (e.g.
  `include '::useradd::login_defs'`, `init.pp`) — legacy style, preserved
  as-is.
- **There is no `data/` dir and no `hiera.yaml`** — this module ships no
  module-level Hiera data. All defaults live in the class parameter lists.

## The `simp_options` / `simplib::lookup` seam

The module's SIMP feature-toggle seam is the UID/GID range configuration, all in
`manifests/login_defs.pp`. Each routes through `simplib::lookup` with an
explicit `default_value` (never assuming `simp_options` is included):

| File | Key | `default_value` |
|------|-----|-----------------|
| `login_defs.pp` | `simp_options::gid::min` | `pick(fact('login_defs.gid_min'), 1000)` |
| `login_defs.pp` | `simp_options::gid::max` | `pick(fact('login_defs.gid_max'), 500000)` |
| `login_defs.pp` | `simp_options::uid::min` | `pick(fact('login_defs.uid_min'), 1000)` |
| `login_defs.pp` | `simp_options::uid::max` | `pick(fact('login_defs.uid_max'), 1000000)` |

Keep routing SIMP feature toggles through `simplib::lookup('simp_options::*', {
'default_value' => ... })` with an explicit default rather than assuming
`simp_options` is included. Note `simp/simp_options` is **not** a declared
dependency in `metadata.json`; the `simp_options::*` keys are consumed via
`simplib::lookup` (from `simp/simplib`).

## Dependencies

Module dependencies (from `metadata.json`):

- `simp/simplib` `>= 4.9.0 < 6.0.0` — provides `simplib::lookup`, the
  `Simplib::Umask` type, and the `login_defs` fact backing the UID/GID defaults.
- `puppetlabs/stdlib` `>= 8.0.0 < 10.0.0` — provides `Stdlib::AbsolutePath`,
  `Stdlib::Filemode`, and `pick()`.
- `puppet/systemd` `>= 4.0.2 < 10.0.0` — provides `systemd::dropin_file`, used by
  `useradd::sysconfig_init` for the emergency/rescue drop-ins.

There are **no optional dependencies** (`metadata.json` has no
`simp.optional_dependencies` block) and no `simplib::assert_optional_dependency`
calls anywhere in the manifests.

Runtime requirement (from `metadata.json`): `openvox >= 8.0.0 < 9.0.0`.
This module has migrated its runtime baseline from Puppet to **OpenVox** — the
`requirements` entry names `openvox`, not `puppet`.

Supported OS matrix (from `metadata.json`): CentOS 9/10; RedHat 8/9/10;
OracleLinux 8/9/10; Rocky 8/9/10; AlmaLinux 8/9/10.

## Repository layout

- `manifests/init.pp` — the `useradd` orchestrator class (`manage_*` toggles,
  `/etc/securetty`, `/etc/shells`).
- `manifests/login_defs.pp` — `/etc/login.defs` (the largest class; UID/GID seam,
  password aging, crypt settings).
- `manifests/useradd.pp` — `/etc/default/useradd`.
- `manifests/libuser_conf.pp` — `/etc/libuser.conf`.
- `manifests/nss.pp` — `/etc/default/nss`.
- `manifests/passwd.pp` — passwd/shadow/group file permissions (parameterless).
- `manifests/etc_profile.pp` — `/etc/profile.d/simp.{sh,csh}` (timeout, umask).
- `manifests/sysconfig_init.pp` — `/etc/sysconfig/init` + systemd
  emergency/rescue drop-ins.
- `types/` — three custom data types: `Useradd::Bootup`
  (`Enum['graphical','color','verbose','plain']`, `types/bootup.pp`),
  `Useradd::CryptStyle` (upper/lowercase `BLOWFISH/DES/MD5/SHA256/SHA512`,
  `types/cryptstyle.pp`), and `Useradd::LibuserModule`
  (`Enum['files','shadow','ldap']`, `types/libusermodule.pp`).
- `templates/` — seven ERB templates mirroring the managed file paths:
  `etc/login_defs.erb`, `etc/default/useradd.erb`, `etc/default/nss.erb`,
  `etc/libuser.conf.erb`, `etc/sysconfig/init.erb`, `etc/profile.d/simp.sh.erb`,
  `etc/profile.d/simp.csh.erb`.
- `metadata.json` — deps, OS matrix, and the OpenVox runtime requirement.
- `spec/spec_helper.rb` — `require 'puppetlabs_spec_helper/module_spec_helper'`.
- `spec/acceptance/suites/default/00_default_spec.rb` — the single beaker
  acceptance suite.
- No `data/`, `hiera.yaml`, or `lib/` — no module Hiera data and no Ruby
  types/providers/functions/facts of its own.
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

- Preserve the `@summary` / `@param` puppet-strings docstrings on each class —
  they drive `REFERENCE.md`. Regenerate `REFERENCE.md` after changing docs or
  parameters.
- One class per managed config file; gate each in the orchestrator with its
  `manage_*` Boolean (`init.pp`). Add new file-management logic as a new
  component class + toggle, following that pattern.
- Route SIMP feature toggles through `simplib::lookup('simp_options::*', {
  'default_value' => ... })` with an explicit default — as the UID/GID params do
  (`login_defs.pp`) — rather than assuming `simp_options` is
  included.
- Constrain enumerable parameters with the `Useradd::*` custom types (or
  `Stdlib::*` / `Simplib::*`) rather than bare `String`, following the existing
  parameter declarations.
- Keep the inline `CCE-*` compliance comments next to the defaults they justify;
  they document the hardening rationale.
- `Gemfile`, `spec/spec_helper.rb`, and `.github/workflows/pr_tests.yml` carry a
  **puppetsync** notice — they are baseline-managed and the next sync overwrites
  local edits. Push changes to those files upstream to the baseline, not here.
- Match the existing 2-space Puppet indentation and aligned-arrow /
  aligned-parameter style used throughout `manifests/`.
