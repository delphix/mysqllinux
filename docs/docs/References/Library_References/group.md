# DXIGroup

Groups in Delphix Virtualization Engine are used to group one or more datasets.
You can think of groups as folders to organize your dSources, VDBs and vFiles.

How to import
------------- 
```python
from dxi.group.dxi_group import DXIGroup
from dxi.group.dxi_group import DXIGroupConstants
```

Create object
-------------
```
   obj = DXIGroup() 
```

Constructor
-------------
```python
class DXIGroup:
    """
    CClass to operate on Delphix Group objects.
    """

    def __init__(
        self,
        engine=DXIGroupConstants.ENGINE_ID,
        single_thread=DXIGroupConstants.SINGLE_THREAD,
        config=DXIGroupConstants.CONFIG,
        log_file_path=DXIGroupConstants.LOG_FILE_PATH,
        poll=DXIGroupConstants.POLL,
        debug=False,
    ):
```

Methods
-------------
Method for all Group related operations.  

###create 
Create a Group on Delphix Engine.

####Signature
```python
    def create(group_name, description):
```

####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | --------
group_name | str |Current group name  | None
description | str | Description for the group | None

###list 
List all Groups on an engine

####Signature
```python
def list(self)
```

###delete 
Delete a Group on Delphix Engine.

#### Signature
```python
def delete(self, group_name)
```

####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
group_name | str |Name of the group to delete | None

###update
Update a Group on Delphix Engine.

#### Signature
```python
def update(self, group_name, new_name, new_description)
```

####Arguments
Argument | Type | Description | Default
-------- | ---- | ----------- | -------- 
group_name | str |Name of the group to update | None
new_name | str |New name for the group | None
new_description | str | New description for the group | None

