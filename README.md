[![Build Status](https://travis-ci.org/icann-dns/puppet-dsc.svg?branch=master)](https://travis-ci.org/icann-dns/puppet-dsc)
[![Puppet Forge](https://img.shields.io/puppetforge/v/icann/dsc.svg?maxAge=2592000)](https://forge.puppet.com/icann/dsc)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/icann/dsc.svg?maxAge=2592000)](https://forge.puppet.com/icann/dsc)
# dsc

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with dsc](#setup)
    * [What dsc affects](#what-dsc-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with dsc](#beginning-with-dsc)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

Installs and manages the [DNS-OARC DNS Statistics Collector (dsc)](https://github.com/DNS-OARC/dsc).

## Module Description

With a default configueration the module will configuer dsc to listen on all real interfaces collecting statistics on an traffic it sees.  It currently uses a Hardcoded set of datatypes.

## Setup

### What dsc affects

 * Installs the dsc collector package
 * creates the data collection directories
 * remove the init.d script installed by the package and installs an upstart script (rc.d script on freebsd)
 * installs our own version of the upload\_prep script.  
 * remove the cron job installed b y the package and install our own
 * manages the dsc-collector service

### Setup Requirements **OPTIONAL**
 
 * stdlib 4.11.0
 * This module uses flock to manage cron jobs and assumes it is already installed on the system.

### Beginning with dsc

Simply add the dsc module to your manifest

```puppet
class { '::dsc': }
```

## Usage

### Local addresses

DSC needs to know the local IP addresses so that it can work out the direction packets are traveling.  By default the module uses the `$::ipaddress` fact however you will often need to override this with a list of address.  These addresses are also used to create the bpf_program filter if it is enabled.

```puppet
class {'::dsc': 
  ip_addresses => ['192.0.2.1'],
  bpf_program => true,
}
```

### Interfaces

If you want to configure dsc to listen on a specific set of interfaces then pass them as an array

```puppet 
class { '::dsc': 
    listen_interfaces => ['eth0', 'eth1']
}
```

## Reference

### Classes

#### Public Classes:
 
 * [`dsc`](#class-dsc)

#### Private Classes:
 
 * [`dsc::params`](#class-dscparams)

##### Parameters (all optional)

  * `prefix` (Path, Default: /usr/local/dsc): The base path for the run_dir
  * `ip_addresses` (Array, Default: [`$::ipaddress`]): Specifies the DNS server's local IP addresses.  It is used to determine the direction of an IP packet: sending, receiving, or other.
  * `bpf_program` (Bool, Default: false): if true create a bfp filter to only capture data destined to the addresses listed in `ip_addresses`
  * `listen_interfaces` (Array, Default: `split($::interfaces, ',')`): An array of interface that dsc should listen on.  It will ignore interfaces starting with lo or dummy.  By default it will use the interfaces listed in the `$::interfaces` fact.
  * `custom_dataset` (Array, Default: []): An array of additional datasets that dsc should use. By default it will use generate the default dsc datasets only.
  * `package` (String, Default: OS specific): The name of the package to install
  * `conf_file` (Path, Default: OS specific): The location of the configueration file to manage
  * `service` (String, Default: OS specific): The name of the service to manage
  * `pid_file` (Path, Default: /var/run/dsc-statistics-collector/default/dsc.pid): The location of the pid file
  * `max_memory` (Int, Default: 4194304): The upstart job limits the rss that dsc can used to this value.  Once this value has been reached dsc will segfault and upstart will restart it
  * `presenter` (/^(dsp|hedgehog)$/, Default: 'dsp'): This is not intended to be used to support multible presenters.  it is somewhat cosmetic at the moment

## Limitations

This module was developed to work with the hedgehog presenter and has not been tested with DSP.

Tested and working on FreeBSD 10 and Ubuntu 14.04

## Development

Since your module is awesome, other users will want to play with it. Let them
know what the ground rules for contributing are.

