# DXIDatabase
​
A Database refers to any dataset in Delphix.  
A Database can be a source (dsource), staging or virtual (vdb or vfiles).
This class provides methods to trigger some of the most commonly used VDB related operations.
​

How to import
----------
```python
from dxi.database.dxi_database import DXIDatabase
from dxi.database.dxi_database import DXIDatabaseConstants
```

Create object
----------

```
   obj = DXIDatabase() 
```

Constructor
----------
```python
​class DXIDatabase:
    """
    Deletes a VDB or a list of VDBs from an engine
    """
    def __init__(
        self,
        name=DXIDatabaseConstants.NAME,
        type=DXIDatabaseConstants.TYPE,
        force=DXIDatabaseConstants.FORCE,
        parallel=DXIDatabaseConstants.PARALLEL,
        engine=DXIDatabaseConstants.ENGINE_ID,
        poll=DXIDatabaseConstants.POLL,
        config=DXIDatabaseConstants.CONFIG,
        log_file_path=DXIDatabaseConstants.LOG_FILE_PATH,
        single_thread=DXIDatabaseConstants.SINGLE_THREAD,
    ):
```

Methods
----------
Methods correspond to operations you can perform on the engine.   

### METHODS FOR PROVISIONING
These methods are used to provision a virtual dataset in Delphix.

### provision_oracle_si
Create an Oracle Standalone VDB.

#### Signature
```python
def provision_oracle_si(self,group,source_name,db_name,env_name,prerefresh=False,postrefresh=False,prerollback=False,postrollback=False,configure_clone=False,port_num=5432,timestamp_type="SNAPSHOT",timestamp="LATEST",mntpoint="/mnt/ingest",env_inst=None,):
```

#### Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
group | str | The group into which Delphix will place the VDB | None 
source_name | str | The source database | None 
db_name | str | The name you want to give the database | None 
env_name | str | The name of the Target environment in Delphix| None 
prerefresh | str | Pre-Hook commands before a refresh | None 
postrefresh | str | Post-Hook commands after a refresh | None 
prerollback | str | Pre-Hook commands before a rollback| None 
postrollback | str | Post-Hook commands after a rollback | None 
configure_clone | str | Configure Clone commands | False 
port_num | str | The port number of the database instance | 5432 
timestamp_type | str | The type of timestamp you are specifying | 'SNAPSHOT'
timestamp | str | The Delphix semantic for the point in time from which you want to ingest your VDB | 'LATEST'
mntpoint | str | The identifier of the instance in Delphix | /mnt/ingest 
env_inst | str | The identifier of the instance in Delphix | None

### provision_oracle_rac
Create an Oracle RAC VDB.

#### Signature
```python
def provision_oracle_rac(self, group, source_name, db_name, env_name,nodes, prerefresh=False, postrefresh=False, prerollback=False, postrollback=False, configure_clone=False, port_num=5432, timestamp_type="SNAPSHOT", timestamp="LATEST", mntpoint="/mnt/ingest", env_inst=None,):
```
#### Arguments
Argument | Type | Description | Default
-------- | ---- | ----------- | -------- 
group | str | The group into which Delphix will place the VDB | None
source_name | str | The source database | None
db_name | str | The name you want to give the database | None
env_name | str | The name of the Target environment in Delphix| None
prerefresh | str | Pre-Hook commands before a refresh | None
postrefresh | str | Post-Hook commands after a refresh | None
prerollback | str | Pre-Hook commands before a rollback| None
postrollback | str | Post-Hook commands after a rollback | None
configure_clone | str | Configure Clone commands | False
port_num | str | The port number of the database instance | 5432
timestamp_type | str | The type of timestamp you are specifying | 'SNAPSHOT'
timestamp | str | The Delphix semantic for the point in time from which you want to ingest your VDB | 'LATEST'
mntpoint | str | The identifier of the instance in Delphix | /mnt/ingest
env_inst | str | The identifier of the instance in Delphix | None

### provision_oracle_mt
Create an Oracle Multi-Tenant VDB.

#### Signature
```python
def provision_oracle_mt(self,group,source_name,db_name,env_name,prerefresh=False,postrefresh=False,prerollback=False,postrollback=False,configure_clone=False,port_num=5432,timestamp_type="SNAPSHOT",timestamp="LATEST",mntpoint="/mnt/ingest",env_inst=None,):
```

#### Arguments
Argument | Type | Description | Default
-------- | ---- | ----------- | -------- 
group | str | The group into which Delphix will place the VDB | None
source_name | str | The source database | None
db_name | str | The name you want to give the database | None
env_name | str | The name of the Target environment in Delphix| None
prerefresh | str | Pre-Hook commands before a refresh | None
postrefresh | str | Post-Hook commands after a refresh | None
prerollback | str | Pre-Hook commands before a rollback| None
postrollback | str | Post-Hook commands after a rollback | None
configure_clone | str | Configure Clone commands | False
port_num | str | The port number of the database instance | 5432
timestamp_type | str | The type of timestamp you are specifying | 'SNAPSHOT'
timestamp | str | The Delphix semantic for the point in time from which you want to ingest your VDB | 'LATEST'
mntpoint | str | The identifier of the instance in Delphix | /mnt/ingest
env_inst | str | The identifier of the instance in Delphix | None

### provision_mssql
Create a MS SQLServer VDB.

#### Signature
```python
def provision_mssql(self,group,source_name,db_name,env_name,prerefresh=False,postrefresh=False,prerollback=False,postrollback=False,configure_clone=False,port_num=5432,timestamp_type="SNAPSHOT",timestamp="LATEST",mntpoint="/mnt/ingest",env_inst=None):
```

#### Arguments
Argument | Type | Description | Default
-------- | ---- | ----------- | -------- 
group | str | The group into which Delphix will place the VDB | None
source_name | str | The source database | None
db_name | str | The name you want to give the database | None
env_name | str | The name of the Target environment in Delphix| None
prerefresh | str | Pre-Hook commands before a refresh | None
postrefresh | str | Post-Hook commands after a refresh | None
prerollback | str | Pre-Hook commands before a rollback| None
postrollback | str | Post-Hook commands after a rollback | None
configure_clone | str | Configure Clone commands | False
port_num | str | The port number of the database instance | 5432
timestamp_type | str | The type of timestamp you are specifying | 'SNAPSHOT'
timestamp | str | The Delphix semantic for the point in time from which you want to ingest your VDB | 'LATEST'
mntpoint | str | The identifier of the instance in Delphix | /mnt/ingest
env_inst | str | The identifier of the instance in Delphix | None


### provision_ase
Create a Sybase ASE VDB.

#### Signature
```python
def provision_ase(self,group,source_name,db_name,env_name,prerefresh=False,postrefresh=False,prerollback=False,postrollback=False,configure_clone=False,port_num=5432,timestamp_type="SNAPSHOT",timestamp="LATEST",mntpoint="/mnt/ingest",env_inst=None,no_truncate_log=False):
```

#### Arguments
Argument | Type | Description | Default
-------- | ---- | ----------- | -------- 
group | str | The group into which Delphix will place the VDB | None
source_name | str | The source database | None
db_name | str | The name you want to give the database | None
env_name | str | The name of the Target environment in Delphix| None
prerefresh | str | Pre-Hook commands before a refresh | None
postrefresh | str | Post-Hook commands after a refresh | None
prerollback | str | Pre-Hook commands before a rollback| None
postrollback | str | Post-Hook commands after a rollback | None
configure_clone | str | Configure Clone commands | False
port_num | str | The port number of the database instance | 5432
timestamp_type | str | The type of timestamp you are specifying | 'SNAPSHOT'
timestamp | str | The Delphix semantic for the point in time from which you want to ingest your VDB | 'LATEST'
mntpoint | str | The identifier of the instance in Delphix | /mnt/ingest
env_inst | str | The identifier of the instance in Delphix | None
no_truncate_log | str | Set the trunc log on chkpt database option | None

### provision_vfiles
Create a vfiles dataset.

#### Signature
```python
def provision_vfiles(self,group,source_name,db_name,env_name,prerefresh=False,postrefresh=False,prerollback=False,postrollback=False,configure_clone=False,port_num=5432,timestamp_type="SNAPSHOT",timestamp="LATEST",mntpoint="/mnt/ingest",env_inst=None,):
```

#### Arguments
Argument | Type | Description | Default
-------- | ---- | ----------- | -------- 
group | str | The group into which Delphix will place the VDB | None
source_name | str | The source database | None
db_name | str | The name you want to give the database | None
env_name | str | The name of the Target environment in Delphix| None
prerefresh | str | Pre-Hook commands before a refresh | None
postrefresh | str | Post-Hook commands after a refresh | None
prerollback | str | Pre-Hook commands before a rollback| None
postrollback | str | Post-Hook commands after a rollback | None
configure_clone | str | Configure Clone commands | False
port_num | str | The port number of the database instance | 5432
timestamp_type | str | The type of timestamp you are specifying | 'SNAPSHOT'
timestamp | str | The Delphix semantic for the point in time from which you want to ingest your VDB | 'LATEST'
mntpoint | str | The identifier of the instance in Delphix | /mnt/ingest
env_inst | str | The identifier of the instance in Delphix | None

### provision_postgres
Create a Postgres VDB.

#### Signature
```python
def provision_postgres(self,group,source_name,db_name,env_name,prerefresh=False,postrefresh=False,prerollback=False,postrollback=False,configure_clone=False,port_num=5432,timestamp_type="SNAPSHOT",timestamp="LATEST",mntpoint="/mnt/ingest",env_inst=None,):
```

#### Arguments
Argument | Type | Description | Default
-------- | ---- | ----------- | -------- 
group | str | The group into which Delphix will place the VDB | None
source_name | str | The source database | None
db_name | str | The name you want to give the database | None
env_name | str | The name of the Target environment in Delphix| None
prerefresh | str | Pre-Hook commands before a refresh | None
postrefresh | str | Post-Hook commands after a refresh | None
prerollback | str | Pre-Hook commands before a rollback| None
postrollback | str | Post-Hook commands after a rollback | None
configure_clone | str | Configure Clone commands | False
port_num | str | The port number of the database instance | 5432
timestamp_type | str | The type of timestamp you are specifying | 'SNAPSHOT'
timestamp | str | The Delphix semantic for the point in time from which you want to ingest your VDB | 'LATEST'
mntpoint | str | The identifier of the instance in Delphix | /mnt/ingest
env_inst | str | The identifier of the instance in Delphix | None


### METHODS FOR INGESTION
These methods are used to ingest data into Delphix.

### ingest_oracle
Ingest a standalone or cluster Oracle database to create a dsource.

#### Signature
```python
def ingest_oracle(self,source_name,db_password,db_user,group,env_inst,logsync=True,env_name=None,ip_addr=None,port_num=None,rman_channels=2,files_per_set=5,num_connections=5,)
```

#### Arguments
Argument | Type | Description | Default
-------- | ---- | ----------- | -------- 
source_name | str | Name of the dSource to create | None
db_password | str | Password for db_user | None
db_user | str | Username of the dSource DB | None
group | str | Group name for this dSource | None
env_inst | str | Location of the installation path of the DB | None
logsync | str | Enable or disable logsync | True
env_name | str | Name of the Delphix environment| None
ip_addr | str | IP Address of the dSource | None
port_num | str | Port number for the Oracle Listener | None
rman_channels | str | Configures the number of Oracle RMAN Channels | None
files_per_set | str | Configures how many files per set for Oracle RMAN | None
num_connections | str | Number of connections for Oracle RMAN | None

### ingest_mssql
Ingest an MS SQLServer DB to create a dsource.

#### Signature
```python
def ingest_mssql(self, source_name, db_password, db_user, group, source_env, stage_env, stage_instance=None, logsync=True, validated_sync_mode="TRANSACTION_LOG", initial_load_type=None, delphix_managed=True, backup_path=None,backup_user_pwd=None,backup_user=None,):
```

#### Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
source_name | str | Name of the dSource to create | None 
db_password | str | Password for db_user | None 
db_user | str | Username of the dSource DB | None 
group | str | Group name for this dSource | None 
source_env | str | Name of the environment where the source DB resides. | None
stage_env | str | Name of the staging environment. | None
stage_instance | str | Name of the SQLServer instance on staging environment.| None
logsync | str | Enable or disable logsync | None 
validated_sync_mode | str | Delphix will try to load the most recent backup | True 
initial_load_type | str | Delphix will try to load the most recent backup | TRANSACTION_LOG 
delphix_managed | str | Delphix will try to load the most recent backup. | True
backup_path | str | Path to the ASE/MSSQL backups | None 
backup_user_pwd | str | Password of the shared backup path | None 
backup_user | str | User of the shared backup path | None 

### ingest_sybase
Ingest an ASE DB to create a dsource.

#### Signature
```python
def ingest_sybase(self, source_name, db_user, db_password, group, source_env, stage_env, stage_instance, backup_path, backup_files=None, logsync=False, create_backup=None)
```

#### Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
source_name | str | Name of the dSource to create | None 
db_password | str | Password for db_user | None 
db_user | str | Username of the dSource DB | None 
group | str | Group name for this dSource | None 
logsync | str | Enable or disable logsync | None 
source_env | str | Name of the environment where the source DB resides. | None
stage_env | str | Name of the staging environment. | None
stage_instance | str | Stage repository| None 
backup_path | str | Path to the ASE/MSSQL backups | None 
backup_files | str | Fully qualified name of backup file | None 
create_backup | str | Create and ingest a new Sybase backup | None 

### OTHER DATABASE OPERATIONS

###delete
Deletes one or more datasets ( dsource, vdb, vfile)
​
####Signature
```python
def delete(self, db_name, db_type="vdb", force=False)
```
####Arguments
Argument | Type | Description | Default
-------- | ---- | ----------- | -------- 
db_name | str |Name of dataset(s) in Delphix to execute against | None
db_type | str | Type of the dataset to delete. vdb | dsource ] | vdb 
force | boolean | Force delete the dataset | False

###refresh
Refresh a Delphix VDB or Vfile.
​
####Signature
```python
def refresh(self,db_name,timestamp_type="SNAPSHOT",timestamp="LATEST",timeflow="None",)
```
####Arguments
Argument | Type | Description | Default
-------- | ---- | ----------- | -------- 
db_name | str | Name of the virtual dataset to refresh | None
timestamp_type | str | The Delphix semantic for the point in time on the source  from which you want to refresh your VDB | SNAPSHOT
timestamp | str | The type of timestamp you are specifying | LATEST
timeflow | str | Name of the timeflow to refresh a VDB  | None

###rewind
Rewinds a Delphix VDB or Vfile.
​
####Signature
```python
def rewind(self,db_name,timestamp_type="SNAPSHOT",timestamp="LATEST",db_type=None,):
```
####Arguments
Argument | Type | Description | Default
-------- | ---- | ----------- | -------- 
db_name | str | Name of the virtual dataset to refresh | None
timestamp_type | str | The Delphix semantic for the point in time on the source  from which you want to refresh your VDB | SNAPSHOT
timestamp | str | The type of timestamp you are specifying | LATEST
db_type | str | Type of database: oracle, mssql, ase, vfiles  | None

###disable
Disable a Virtual dataset.

#### Signature
```python
def disable(self, db_name, group=None, force=False)
```

#### Arguments
Argument | Type | Description | Default
-------- | ---- | ----------- | -------- 
db_name | str | Name of the virtual dataset to disable | None
group | str | Group where the dataset resides | None
force | bool | Force disable a virtual dataset| False


###enable
Disable a Virtual dataset.

#### Signature
```python
def enable(self, db_name, group=None)
```

#### Arguments
Argument | Type | Description | Default
-------- | ---- | ----------- | -------- 
db_name | str | Name of the virtual dataset to enable | None
group | str | Group where the dataset resides | None

### list
List all datasets on an engine.

#### Signature
```python
def list(self)
```

### start
Start a Virtual dataset.

#### Signature
```python
def start(self, db_name, group=None)
```

#### Arguments
Argument | Type | Description | Default
-------- | ---- | ----------- | -------- 
db_name | str | Name of the virtual dataset to start | None
group | str | Group where the dataset resides | None

### stop
Stop a Virtual dataset.

#### Signature
```python
def stop(self, db_name, group=None)
```

#### Arguments
Argument | Type | Description | Default
-------- | ---- | ----------- | -------- 
name | str | Name of the virtual dataset to stop | None
group | str | Group where the dataset resides | None 
