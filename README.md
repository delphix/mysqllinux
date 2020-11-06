## 
## What Does a Delphix Plugin Do?
Delphix is a data management platform that provides the ability to securely copy and share datasets. Using virtualization, you will ingest your data sources and create virtual data copies, which are full read-write capable database instances that use a small fraction of the resources a normal database copy would require. The Delphix engine has built-in support for interfacing with certain types of datasets, such as Oracle, SQL Server and ASE.

The Delphix virtualization SDK (https://github.com/delphix/virtualization-sdk) provides an interface for building custom data source integrations for the Delphix Dynamic Data Platform. The end users can design/implement a custom plugin which enable them to use custom data source like MySQL, MongoDB, Cassandra, MySQL or something else similar to as if they are using a built-in dataset type with Delphix Engine.

## MySQL Plugin
MySQL plugin is developed to virtualize MySQL data source leveraging the following built-in MySQL technologies:
Features:
  - Environment Discovery: MySQL plugin can discover environments where MySQL server is installed.
  - Ingesting Data: Create a dSource using differnt methods specified below. 
  - VDB Creation: Single node MySQL VDB can be provisioned from the dsource snapshot.

Different Ways to Ingest Data ( Dsource creation )
  - Replication with Delphix initiated Backup: Delphix takes an initial backup from source DB to ingest data and create a dSource. Delphix also sets up a master-slave replication to keep this dSource in sync with the source database. User can select the databases they want to virtualize
  - Replication with User Provided Backup: User provides a backup file from source DB to ingest data and create a dSource. Delphix sets up a master-slave replication to keep this dSource in sync with your source database. 
  - User Provided Backup with no Replication: User provides a backup file from source DB to ingest data and create a dSource. When a new backup is available, user initiates a resync of the dSource to ingest data from the new backup.
  - Manual Backup Ingestion: Delphix creates an empty seed datanase and User manually ingests a backup to create a dSource.
  - Simple Tablespace Backup/Subsetting: Allows to create a dSource using a specific list of tables from source database.
 

### Table of Contents
1. [Prerequisites](#requirements-plugin)
2. [Build and Upload Plugin](#upload-plugin)
3. [Download logs](#run_unit_test_case)
4. [Tested Versions](#tested-versions)
5. [Supported Features](#support-features)
6. [Unsupported Features](#unsupported-features)
7. [How to Contribute](#contribute)
8. [Statement of Support](#statement-of-support)
9. [License](#license)


### <a id="requirements-plugin"></a>Prerequisites
**Software Requirements**
1. jq - This toolkit requires jq to be configured on Staging and Target Hosts. 

**MySQL instance requirements**
1. Binary logging must be enabled on MySQL source instance.
2. Server ID for the source must be greater than 0.
    
**MySQL database user with following privileges**
1. delphixdb
This MySQL user must be configured to have following privilege from the Delphix Engine IP, the staging host IP and localhost
To grant the privilege for this user, use the following command:

```js
SQL> GRANT SELECT, SHUTDOWN, SUPER, RELOAD, REPLICATION CLIENT,REPLICATION SLAVE,SHOW VIEW, EVENT, TRIGGER on *.* to 'delphix'@'%';
```

OR

```js
SQL> GRANT ALL PRIVILEGES ON *.* TO '<delphix>'@'%';
```

#### _Staging Host Specific Requirements_

**O/S user with following privileges**
1. Regular o/s user. should be able to ps all processes.
2. Should be in the same primary and secondary groups as mysql user ( or the MySQL binary owner )
3. Execute access on all files within MySQL installation folder - Min permission level 775 recommended. 
4. Sudo privileges for mount, umount. See sample below assuming `delphix_os` is used as delphix user.
Example sudoers file entry
```shell
Defaults:delphix_os !requiretty
delphix_os ALL=NOPASSWD: \ 
/bin/mount, /bin/umount, /bin/mkdir, /bin/rmdir, /bin/ps

**Other Staging Host Requirements**

1. Same version as Source MySQL Binaries installed.
2. A MySQL config file (my.cnf) to be used for the Staging DB instance must be available under Delphix Toolkit Directory. 
3. Empty folder on host to hold delphix toolkit  [ approximate 2GB free space ]
4. Empty folder on host to mount nfs filesystem. This is just and empty folder with no space requirements and act as base folder for nfs mounts.


#### _Target Requirements_

**O/S user with following privileges**
1. Regular o/s user. should be able to ps all processes.
2. Should be in the same primary and secondary groups as mysql user ( or the MySQL binary owner )
3. Execute access on all files within MySQL installation folder - Min permission level 775 recommended. 
4. Sudo privileges for mount, umount. See sample below assuming `delphix_os` is used as delphix user.
Example sudoers file entry
```shell
Defaults:delphix_os !requiretty
delphix_os ALL=NOPASSWD: \ 
/bin/mount, /bin/umount, /bin/mkdir, /bin/rmdir, /bin/ps

**Other Staging Host Requirements**

1. Same version as Source MySQL Binaries installed.
2. A MySQL config file (my.cnf) to be used for the Staging DB instance must be available under Delphix Toolkit Directory. 
3. Empty folder on host to hold delphix toolkit  [ approximate 2GB free space ]
4. Empty folder on host to mount nfs filesystem. This is just and empty folder with no space requirements and act as base folder for nfs mounts.


### <a id="upload-plugin"></a>Steps to build, upload and run unit tests for plugin

   1. Build the source code. It generates the build with name `artifacts.json`:
```bash
    dvp build
```
    
   2. Upload the `artifacts.json` ( generated in step 3 ) on Delphix Engine:
```bash
    dvp upload -e <Delphix_Engine_Name> -u <username> --password <password>
```


### <a id="run_unit_test_case"></a>Download plugin logs
#### Plugin Logs:
Download the plugin logs using below command:

```dvp download-logs -c plugin_config.yml -e <Delphix_Engine_Name> -u admin --password <password>```


### <a id="tested-versions"></a>Tested Versions
- Delphix Engine: 6.0.2 and above
- MySQL Version: 5.7.7, 5.7.9, 5.7.10, 5.7.12   
- Linux Version: RHEL 6.x

### <a id="support-features"></a>Supported Features
- MySQL Replication
- MySQL Tablespace Hotbackup

### <a id="unsupported-features"></a>Unsupported Features
- MySQL Clusters
- Sharded MySQL Databases


### <a id="contribute"></a>How to Contribute

Please read [CONTRIBUTING.md](./CONTRIBUTING.md) to understand the pull requests process.

### <a id="statement-of-support"></a>Statement of Support

This software is provided as-is, without warranty of any kind or commercial support through Delphix. See the associated license for additional details. Questions, issues, feature requests, and contributions should be directed to the community as outlined in the [Delphix Community Guidelines](https://delphix.github.io/community-guidelines.html).

### <a id="license"></a>License

This is code is licensed under the Apache License 2.0. Full license is available [here](./LICENSE).

