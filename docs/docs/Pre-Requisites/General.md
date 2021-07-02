# General

Given below are the general pre-requisites for MySQL virtualization.

### Environments
For MySQL virtualization, Delphix requies only Staging and Target Hosts to be added as environments. 

Refer to [Delphix Docs](https://docs.delphix.com/docs/configuration/performance-analytics-management/target-host-os-and-database-configuration-options) 
for configuration best practices. 

##### Staging Host/Environment
   The MySQL plugin is a "Staged" plugin - which means that in order to create a dSource, Delphix requires a staging environment.
   This environment must have MySQL binaries installed and the version of MySQL must match the source MySQL database(s).

##### Target Host/Environment
 If you are familiar with Delphix, you must already know what a Target Host is.
 It is simply another host with MySQL binaries installed where Delphix creates virtual databases.
 Again, the version of MySQL must match your source database(s).

### Storage
- Empty folder on Staging & Target host to hold delphix toolkit [ approximate 2GB free space ]
- If Delphix is managing backups, the Staging Host must have enough storage space to hold your source database backup.

### MySQL Version
- MySQL Binary version on Staging and Target must match the version on the source database(s)


