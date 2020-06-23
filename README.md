# manage_ca_file

Synchrozies certificates from differing Puppet CAs so that thier agents can be used with both.

## Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with manage_ca_file](#setup)
    * [Beginning with manage_ca_file](#beginning-with-manage_ca_file)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

You may be in an environment where you're agents must talk to multiple PE environments that use different certificate authorities.

For this to work you're agents must carry credentials for both certificate authories.

This module manages the credentials for these agents.

## Setup

### Beginning with manage_ca_file

This module contains a plan runs on a local CA and takes the hostname for the remote CA as an argument.

It's easiest to run this directly on the PE console of the 'local' CA.

You can run using bolt locally, but you must integrate PE client tools to talk to the 'local' CA.

## Usage

Run from the PE console.

or

`bolt plan run manage_ca_file::sync_cas remote_ca_hostname=<value>`

## Limitations

This project has been tested on PE versions of 2019.x.

## Development

We thank the community and appreciate contributions.
