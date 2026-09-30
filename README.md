[![License](https://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/useradd.svg)](https://forge.puppetlabs.com/simp/useradd)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/useradd.svg)](https://forge.puppetlabs.com/simp/useradd)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-useradd.svg)](https://travis-ci.org/simp/pupmod-simp-useradd)

#### Table of Contents

1. [Breaking changes in 4.0.0](#breaking-changes-in-400)
1. [Description](#description)
2. [Setup - The basics of getting started with useradd](#setup)
    * [What useradd affects](#what-useradd-affects)
    * [Beginning with useradd](#beginning-with-useradd)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Deprecations](#deprecations)
7. [Development - Guide for contributing to the module](#development)
    * [Acceptance Tests - Beaker env variables](#acceptance-tests)


## Breaking changes in 4.0.0

### A bare include manages nothing

`include useradd` no longer writes any file. Each setting is managed only when
its parameter is set, and an unset parameter leaves the system alone.

To get the 3.x behavior back, either:

* enforce the `simp:defaults` compliance profile, which ships with this module:

  ```yaml
  compliance_engine::enforcement:
    - simp:defaults
  ```

* or set the parameters you need in Hiera.

Values set in site Hiera take precedence over the profile.

### Files are edited in place

* `/etc/login.defs`, `/etc/default/useradd`, `/etc/default/nss`,
  `/etc/libuser.conf` and `/etc/sysconfig/init` are edited one key per
  parameter. `absent` removes a key.
* `/etc/securetty` and `/etc/shells` are edited one entry at a time, through
  `securetty_entries` and `shells_entries`.
* Keys and entries the module doesn't set are kept, unless you turn on the
  matching `purge` parameter. `simp:defaults` turns them on.
* An empty or whitespace-only `login_defs` value (such as `''`) is skipped
  with a deprecation warning. `login.defs` can't hold a key with no value.
* A value with a space or a leading quote that ends in a backslash, or has a
  backslash before both a `"` and a `'`, fails compilation. Augeas can't
  write it; 3.x wrote it verbatim.

3.x wrote an empty value as the key alone on a line (such as
`LOGIN_STRING`, perhaps followed by whitespace), which can't be parsed. While
the parameter is still empty, the module removes that line. If you have
already removed the value from Hiera, remove the line by hand, or every
`login_defs` edit fails on it.

### Single-user login drop-ins

`useradd::sysconfig_init::single_user_login` writes the emergency and rescue
drop-ins with plain `file` resources and its own `daemon-reload`.

* The drop-in directories are purged only when `purge_dropins` is `true`, or,
  with `useradd::sysconfig_init::systemd: true`, when
  `systemd::purge_dropin_dirs` is. `simp:defaults` sets `systemd: true`, as
  in 3.x.
* If another module declares a `systemd::dropin_file` on `emergency.service`
  or `rescue.service`, set `useradd::sysconfig_init::systemd: true` so both
  declare the directory the same way. Without `systemd: true`,
  `purge_dropins: true` also matches while `systemd::purge_dropin_dirs` is
  at its default; it removes the other drop-ins for those units, as
  `systemd::dropin_file` would.

### UID/GID ranges

3.x always wrote `UID_MIN`, `UID_MAX`, `GID_MIN` and `GID_MAX` to
`login.defs`, from `simp_options::uid`/`gid`, else the current value, else
1000/1000000/1000/500000. 4.0.0 writes them only when set, directly or through
`simp_options`. `simp:defaults` doesn't set them.

* A host that already has the keys keeps its values.
* A `login.defs` missing a key no longer gets the 3.x fallback. Set the
  parameter to keep it.

### Login scripts

`/etc/profile.d/simp.sh` and `simp.csh` are replaced by one file per setting
(`simp-b-tmout.sh`, `zz-simp-umask.sh`, and so on), `simp:defaults` included.

* `useradd::etc_profile::purge_legacy_simp_sh: true` removes the old files.
  `simp:defaults` sets it.
* Otherwise they are left alone, and still apply their settings at login,
  including ones you set to `absent`. If you set `prepend` or `append`, that
  content runs twice, and the module warns.
* The csh `prepend` now runs after the other `/etc/profile.d` csh scripts
  that sort after `simp.csh`.
* A `prepend` that returns early no longer skips the other settings.

### Deprecated parameters

These still work, and warn when set:

* the `manage_*` parameters of `useradd`, where `false` still skips the class;
* `securetty`, `shells_default` and `shells`, replaced by `securetty_entries`
  and `shells_entries`. As in 3.x, each owns its whole file, and the matching
  `*_entries` and `purge_*` parameters are ignored;
* `useradd::etc_profile::manage_tmout`;
* `useradd::libuser_conf::userdefaults` and `groupdefaults`, replaced by
  `userdefaults_settings` and `groupdefaults_settings`. As in 3.x, each is
  its whole section, and the matching Hash is ignored.

See the [CHANGELOG](./CHANGELOG) for the full list.


## Description

useradd is a Puppet module that manages settings regarding users and user creation.


### This is a SIMP module

This module is a component of the [System Integrity Management Platform](https://simp-project.com),
a compliance-management framework built on Puppet.

If you find any issues, they may be submitted to our [bug tracker](https://simp-project.atlassian.net/).

This module is optimally designed for use within a larger SIMP ecosystem, but it can be used independently:

 * When included within the SIMP ecosystem, security compliance settings will be managed from the Puppet server.
 * If used independently, all SIMP-managed security subsystems are disabled by default and must be explicitly opted into by administrators.  Please review the `$client_nets`, `$enable_*` and `$use_*` parameters in `manifests/init.pp` for details.


## Setup


### What useradd affects

This module can configure:
  * `/etc/default/useradd`
  * `/etc/group`
  * `/etc/group-`
  * `/etc/gshadow`
  * `/etc/gshadow-`
  * `/etc/libuser.conf`
  * `/etc/login.defs`
  * `/etc/passwd`
  * `/etc/passwd-`
  * `/etc/profile.d/`
  * `/etc/securetty`
  * `/etc/shadow`
  * `/etc/shadow-`
  * `/etc/shells`
  * `/etc/systemd/system/{emergency,rescue}.service.d/`


### Beginning with useradd

Include the class and set the parameters you want managed, or enforce the
`simp:defaults` profile:

```yaml
---
classes:
  - useradd

compliance_engine::enforcement:
  - simp:defaults
```


## Usage

Set only what you want enforced. For example, to enforce a password age and
an idle-session timeout and leave everything else alone:

```yaml
---
useradd::login_defs::pass_max_days: 60
useradd::etc_profile::session_timeout: 15
```

Removing a key from Hiera later leaves the value on the node. To remove it,
set it to `absent`:

```yaml
---
useradd::login_defs::pass_max_days: absent
```

Lists are Hashes, merged across Hiera layers, so one layer can add or remove a
single entry:

```yaml
---
useradd::securetty_entries:
  console: {}
  tty4:
    ensure: absent
```


## Reference

Please refer to the [REFERENCE.md](./REFERENCE.md).

## Deprecations

As of version 1.0.0, this module will no longer manage `/etc/security/opasswd`. Version 7.0.0 and above of the [SIMP PAM Module](https://github.com/simp/pupmod-simp-pam) will allow users to specify the file they wish to store historical passwords in.

## Limitations

SIMP Puppet modules are generally intended for use on Red Hat Enterprise Linux and compatible distributions, such as CentOS. Please see the [`metadata.json` file](./metadata.json) for the most up-to-date list of supported operating systems, Puppet versions, and module dependencies.


## Development

Please read our [Contribution Guide] (https://simp.readthedocs.io/en/stable/contributors_guide/index.html)
