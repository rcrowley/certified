Certified
=========

Installation
------------

```sh
sudo make install
```

Usage
-----

Generate your CA:

```sh
certified-ca C="US" ST="CA" L="San Francisco" O="Example" CN="Example CA"
```

Generate a wildcard certificate:

```sh
certified CN="internal.example.com" +"*.internal.example.com"
```

Generate a certificate with several DNS names:

```sh
certified CN="ops.example.com" +"git.ops.example.com" +"jenkins.ops.example.com"
```

Generate a certificate for an IP address:

```sh
certified CN="localhost" +"127.0.0.1"
```

The [wiki](https://github.com/rcrowley/certified/wiki) documents common usage patterns and how to use your CA with various browsers, operating systems, and programming languages.

TODO
----

* Example TLS clients that verify certificates with the CA (in various languages).
* Example TLS servers that use one of these certificates (in various languages).
* Help users with PFS.
* Help users with session resumption.
* Help users run OSCP responders.

TODONE
------

* Generate a CA.
* Generate certificates signed by the CA.
* Generate self-signed certificates.
* Revoke and regenerate certificates.
* Support DNS and IP subject alternative names.
* Prevent invalid DNS names, wildcards, and IPs.
* Commit changes to a Git repository.
* Generate basic CRLs.
* Installer.
* Uninstaller.
* `man` pages.
* Document how to install the CA on Linux.
* Document how to install the CA so browsers can use it.
* Document how to run a CA like Betable's.
* Decouple private keys and certificate signing requests from the signing itself.
* Document GPG-encrypted backups of your CA.
* YAML generator for use with Hiera/Puppet.
* Document how to run an autosigning sub-CA.
* Tag certificates with CRL distribution points and OCSP responder URLs.
