Manage local metadata
=====================

The `LocalDynamicMetadataProvider` in Shibboleth Identity Provider expects files in a directory to be named using a hash of the entityID of the entity they represent.

For example, if the entityID were `urn:test:foobar`, the filename would be `d278c9975472a6b4827b1a8723192b4e99aa969c.xml`:

```
$ echo -n "urn:test:foobar" | openssl sha1
d278c9975472a6b4827b1a8723192b4e99aa969c
```

See also: https://shibboleth.atlassian.net/wiki/spaces/IDP4/pages/1265631642/LocalDynamicMetadataProvider

This script manages a target directory by creating symlinks to a source directory of files by looking up the entityID within each file and, optionally, tidying up the superfluous ones.

Running
-------
```
Usage: manage.pl -s <source> -d <target> [ -t ] [ -v num ]

  -s dir   source
  -d dir   target / destination
  -t       tidy dangling files
  -v num   log level (0-6; default=4)
```

Example
-------
```
$ perl manage.pl -s in -d out -t
[2021-11-11 11:18:37] INFO    Starting to process 32 files
[2021-11-11 11:18:38] INFO    Created symlink .../in/mymetadata.xml <-- out/d278c9975472a6b4827b1a8723192b4e99aa969c.xml
```

