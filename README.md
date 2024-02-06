[![License](https://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/useradd.svg)](https://forge.puppetlabs.com/simp/useradd)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/useradd.svg)](https://forge.puppetlabs.com/simp/useradd)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-useradd.svg)](https://travis-ci.org/simp/pupmod-simp-useradd)

#### Table of Contents

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
  * `/etc/default/nss`
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
  * `/etc/sysconfig/init`


### Beginning with useradd

To use this module with it's default settings, just instantiate it. The following example is in hiera:

```yaml
---
classes:
  - useradd

```


## Usage

Each file can be managed or unmanaged individually, using the following variables:
  * useradd::manage_etc_profile
  * useradd::manage_libuser_conf
  * useradd::manage_login_defs
  * useradd::manage_nss
  * useradd::manage_passwd_perms
  * useradd::manage_sysconfig_init
  * useradd::manage_useradd


## Reference

Please refer to the [REFERENCE.md](./REFERENCE.md).

## Deprecations

As of version 1.0.0, this module will no longer manage `/etc/security/opasswd`. Version 7.0.0 and above of the [SIMP PAM Module](https://github.com/simp/pupmod-simp-pam) will allow users to specify the file they wish to store historical passwords in.

## Limitations

SIMP Puppet modules are generally intended for use on Red Hat Enterprise Linux and compatible distributions, such as CentOS. Please see the [`metadata.json` file](./metadata.json) for the most up-to-date list of supported operating systems, Puppet versions, and module dependencies.


## Development

Please read our [Contribution Guide] (https://simp.readthedocs.io/en/stable/contributors_guide/index.html)
