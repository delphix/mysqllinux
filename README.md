## 
## What Does a Delphix Plugin Do?
Delphix is a data management platform that provides the ability to securely copy and share datasets. Using virtualization, you will ingest your data sources and create virtual data copies, which are full read-write capable database instances that use a small fraction of the resources a normal database copy would require. The Delphix engine has built-in support for interfacing with certain types of datasets, such as Oracle, SQL Server and ASE.

The Delphix virtualization SDK (https://github.com/delphix/virtualization-sdk) provides an interface for building custom data source integrations for the Delphix Dynamic Data Platform. The end users can design/implement a custom plugin which enable them to use custom data source like MySQL, MongoDB, Cassandra, MySQL or something else similar to as if they are using a built-in dataset type with Delphix Engine.

## MySQL Plugin
MySQL plugin is developed to virtualize MySQL data source leveraging the following built-in MySQL technologies:
  - Replication: Allows staging MySQL instance to be kept in sync with teh source database. 
  - Ingest Backup: Dsource can be created by ingesting a MySQL backup. 
  - Subsetting: Allows to create a dSource using a specific list of tables from source database.
  - Environment Discovery: MySQL plugin can discover environments where MySQL server is installed.
  - VDB Creation: Single node MySQL VDB can be provisioned from the dsource snapshot.


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
**MySQL instance requirements**
1. Binary logging must be enabled on MySQL source instance.
2. Server ID for the source must be greater than 0.
    
**MySQL database user with following privileges**
1. delphixdb
This MySQL user must be configured to have following privilege from the Delphix Engine IP as well as the staging host IP.
To grant the privilege for this user, use the following command:

```js
SQL> GRANT SELECT, RELOAD, REPLICATION CLIENT,REPLICATION SLAVE,SHOW VIEW, EVENT, TRIGGER on *.* to 'delphix'@'%';
```

OR

```js
SQL> GRANT ALL PRIVILEGES ON *.* TO '<delphix>'@'%';
```

#### _Staging Requirements_

**O/S user with following privileges**

1. Same version as Source MySQL Binaries installed.
2. A MySQL config file (my.cnf) to be used for the Staging DB instance must be available under Delphix Toolkit Directory. 
3. Regular o/s user. should be able to ps all processes.
4. Execute access on mysqldump, mysqld, mysql binary
5. Empty folder on host to hold delphix toolkit  [ approximate 2GB free space ]
6. Empty folder on host to mount nfs filesystem. This is just and empty folder with no space requirements and act as base folder for nfs mounts.
7. sudo privileges for mount, umount. See sample below assuming `delphix_os` is used as delphix user.

```shell
Defaults:delphix_os !requiretty
delphix_os ALL=NOPASSWD: \ 
/bin/mount, /bin/umount
```

#### _Target Requirements_

**O/S user with following privileges**

1. Same version as Source MySQL Binaries installed.
2. A MySQL config file (my.cnf) to be used for the Staging DB instance must be available under Delphix Toolkit Directory. 
3. Regular o/s user. should be able to ps all processes.
4. Execute access on mysqldump, mysqld, mysql binary
5. Empty folder on host to hold delphix toolkit  [ approximate 2GB free space ]
6. Empty folder on host to mount nfs filesystem. This is just and empty folder with no space requirements and act as base folder for nfs mounts.
7. sudo privileges for mount, umount. See sample below assuming `delphix_os` is used as delphix user.

```shell
Defaults:delphix_os !requiretty
delphix_os ALL=NOPASSWD: \ 
/bin/mount, /bin/umount
```


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

