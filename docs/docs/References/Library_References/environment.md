# DXIEnvironment
​
An Environment in Delphix is a Windows/ Linux / Unix Host that has been linked to Delphix. 
An Environment may be a Source Host or Staging Host or Target Host.
​
This class provides methods for commonly used environment related operations.
​

How to import
----------
```python
from dxi.environment.dxi_environment import DXIEnvironment
from dxi.environment.dxi_environment import  EnvironmentConstants
```

Create object
----------

```
   obj = DXIEnvironment() 
```

Constructor
----------
```python
​class DXIEnvironment:
        """
        Perform an environment operation
        """
        
        def __init__(
            self,
            engine=EnvironmentConstants.ENGINE_ID,
            log_file_path=EnvironmentConstants.LOG_FILE_PATH,
            config_file=EnvironmentConstants.CONFIG,
            poll=EnvironmentConstants.POLL,
            single_thread=EnvironmentConstants.SINGLE_THREAD,
            parallel=EnvironmentConstants.PARALLEL,
            action=EnvironmentConstants.ACTION,
            module_name=EnvironmentConstants.MODULE_NAME,
        )

```

Methods
----------
Methods correspond to operations you can perform on the engine.   
​
###add 
To add an environment on a engine.
​
####Signature
```python
def add(self, env_name=None, env_type=None, host_ip=None, toolkit_dir=None, os_user=None, os_user_pwd=None, connector_env_name=None, ase_db_user=None, ase_db_user_pwd=None,)
```
####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
env_name | str | Name of the environment in Delphix | None 
env_type | str | Type of the environment [ unix or windows ] | None 
host_ip | str | IP address or Hostname of the environment | None 
toolkit_dir | str | Directory on the Unix/Linux environment to download Delphix Toolkit | None 
os_user | str | Delphix OS user on the host environment | None 
os_user_pwd | str | Delphix OS user password | None 
connector_env_name | str | Name of the environment on which Windows connector is installed and running | None
ase_db_user | str | ASE DB username | None
ase_db_user_pwd | str | ASE DB user's password |None
​


###​delete 
Delete an environment by name.
​
####Signature
```python
def delete(self,env_name)
```
####Arguments
Argument | Type | Description | Default 
-------- | ---- | ----------- | -------- 
env_name | str | Name of the environment in Delphix | None 


###enable 
Enable an environment by name
​
####Signature
```python
def enable(self,env_name)
```
####Arguments
Argument | Type | Description | Default 
-------- | ---- | ----------- | -------- 
env_name | str | Name of the environment in Delphix | None 
​


###disable 
Disable an environment by name
​
####Signature
```python
def disable(self,env_name)
```
####Arguments
Argument | Type | Description | Default 
-------- | ---- | ----------- | -------- 
env_name | str | Name of the environment in Delphix | None 
​


###list 
List all environments on an engine
​
####Signature
```python
def list(self)
```

###refresh 
Refresh an environment by name
​
####Signature
```python
def refresh(self,env_name)
```
####Arguments
Argument | Type | Description | Default 
-------- | ---- | ----------- | -------- 
env_name | str | Name of the environment in Delphix | None 


### updatehost 
Update an environment's IP address
​
####Signature
```python
def refresh(self,old_host, new_host)
```
####Arguments
Argument | Type | Description | Default 
-------- | ---- | ----------- | -------- 
old_host | str | Old IP Address of the environment to update | None 
new_host | str | New IP or HostName of the environment | None 