# DXIContainer

A Container (Self Service Container) in Delphix refers to set of Virtual Datasets.
that are grouped together and can be operated on as a single unit through Delphix Self Service.

This class provides methods to trigger some of the most commonly used container related operations.

How to import 
-------------
```python
from dxi.container.dxi_container import DXIContainer
from dxi.container.dxi_container import DXIContainerConstants
```

Create Object
-------------
```
   obj = DXIContainer() 
```

Constructor
--------
```python
class DXIContainer:
    """
    Create a snapshot a dSource or VDB
    """

    def __init__(
        self,
        engine=DXIContainerConstants.ENGINE_ID,
        single_thread=DXIContainerConstants.SINGLE_THREAD,
        config=DXIContainerConstants.CONFIG,
        log_file_path=DXIContainerConstants.LOG_FILE_PATH,
        poll=DXIContainerConstants.POLL,
    ):
```
  
###create
Create the SS container

####Signature
```python
def create(self, container_name, template_name, database_name)
```

####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
container_name | str | Name of the SS Container | None 
template_name | str | Name of the JS Template to use for the container | None 
database_name | str | Name of the child database(s) to use for the SS Container| None 


###delete
Delete the SS container

####Signature
```python
def delete(self, container_name, keep_vdbs=False)
```

####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
container_name | str | Name of the SS Container | None 
keep_vdbs | bool | If set, deleting the container will not remove the underlying VDB | False 

###refresh
Refreshes a container

####Signature
```python
def refresh(self, container_name)
```

####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
container_name | str | Name of the SS Container | None

###reset
Reset a container

####Signature
```python
def reset(self, container_name)
```

####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
container_name | str | Name of the SS Container | None  

###list
Give all containers on a given engine

####Signature
```python
def list(self)
```

###connection_info
List all database connection info

####Signature
```python
def connection_info(self, container_name)
```

####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
container_name | str | Name of the SS Container | None  


###add_owner
Adds an owner to a container

####Signature
```python
def add_owner(self, container_name, template_name)
```

####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
container_name | str | Name of the SS Container | None 
template_name | str | Name of the JS Template to use for the container | None 

###remove_owner
Removes an owner to a container

####Signature
```python
def remove_owner(self, container_name, template_name)
```

####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
container_name | str | Name of the SS Container | None 
template_name | str | Name of the JS Template to use for the container | None 