# MySQL Plugin 2.0.26

To install dxi, refer to [Plugin Installation](/PluginInstallation/index.html)

###New Features

-  Selecting Databases : Ability to select specific databases in the Source MySQL server when creating a dSource.
-  Delphix generated config file : If a my.cnf file is not provided while creating a dSource, Delphix now creates one. 
-  New Exit Return Codes : MySQL Plugin 2.0.26 introduces more granular exit codes for errors. 

###Breaking Changes 
-  Removed Simple Tablespace Backup: MySQL Plugin does not support the Simple Tablespace Backup option for Linking. This option may be supported in the future.

###Supported versions

The current release supports  

- All MySQL 5.7 versions greater than 5.7.6
- RHEL 6.9 / 7.x
- Delphix Engine 6.0.4 and above

Future releases may add support for additional versions.

Questions?
----------------
If you have questions, bugs or feature requests reach out to us via the [MySQL Github](https://github.com/delphix/mysqllinux/) or
at [Delphix Community Portal](https://community.delphix.com/home)