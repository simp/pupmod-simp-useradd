[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html) [![Build Status](https://travis-ci.org/simp/pupmod-simp-useradd.svg)](https://travis-ci.org/simp/pupmod-simp-useradd) [![SIMP compatibility](https://img.shields.io/badge/SIMP%20compatibility-4.2.*%2F5.1.*-orange.svg)](https://img.shields.io/badge/SIMP%20compatibility-4.2.*%2F5.1.*-orange.svg)

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with useradd](#setup)
    * [What useradd affects](#what-useradd-affects)
    * [Beginning with useradd](#beginning-with-useradd)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
    * [Acceptance Tests - Beaker env variables](#acceptance-tests)


## Description

useradd is a Puppet module that manages settings regarding users and user creation.


### This is a SIMP module

This module is a component of the [System Integrity Management Platform](https://github.com/NationalSecurityAgency/SIMP), a compliance-management framework built on Puppet.

If you find any issues, they may be submitted to our [bug tracker](https://simp-project.atlassian.net/).

This module is optimally designed for use within a larger SIMP ecosystem, but it can be used independently:

 * When included within the SIMP ecosystem, security compliance settings will be managed from the Puppet server.
 * If used independently, all SIMP-managed security subsystems are disabled by default and must be explicitly opted into by administrators.  Please review the `$client_nets`, `$enable_*` and `$use_*` parameters in `manifests/init.pp` for details.


## Setup


### What useradd affects

This module configures:
  * `/etc/libuser.conf`
  * `/etc/login.defs`
  * `/etc/default/nss`
  * `/etc/default/useradd`
  * `/etc/profile.d/`
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
  * useradd::manage_useradd
  * useradd::manage_login_defs
  * useradd::manage_libuser_conf
  * useradd::manage_etc_profile
  * useradd::manage_sysconfig_init


## Reference

Please refer to the inline documentation within each source file, or to the module's generated YARD documentation for reference material.


## Limitations

SIMP Puppet modules are generally intended for use on Red Hat Enterprise Linux and compatible distributions, such as CentOS. Please see the [`metadata.json` file](./metadata.json) for the most up-to-date list of supported operating systems, Puppet versions, and module dependencies.


## Development

Please read our [Contribution Guide](https://simp-project.atlassian.net/wiki/display/SD/Contributing+to+SIMP) and visit our [developer wiki](https://simp-project.atlassian.net/wiki/display/SD/SIMP+Development+Home).


### Acceptance tests

This module includes [Beaker](https://github.com/puppetlabs/beaker) acceptance tests using the SIMP [Beaker Helpers](https://github.com/simp/rubygem-simp-beaker-helpers).  By default the tests use [Vagrant](https://www.vagrantup.com/) with [VirtualBox](https://www.virtualbox.org) as a back-end; Vagrant and VirtualBox must both be installed to run these tests without modification. To execute the tests run the following:

```shell
bundle install
bundle exec rake beaker:suites
```

Please refer to the [SIMP Beaker Helpers documentation](https://github.com/simp/rubygem-simp-beaker-helpers/blob/master/README.md) for more information.
