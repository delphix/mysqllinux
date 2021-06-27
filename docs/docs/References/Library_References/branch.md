# DXIBranch

A branch (Self Service Container Branch) allows you create 
multiple versions of your data within a container, just as you would do with code.

This class provides methods to trigger some of the most commonly used branch related operations.

How to import
-------------
```python
from dxi.branch.dxi_branch import DXIBranch
from dxi.branch.dxi_branch import DXIBranchConstants
```

Create object
-------------
```
   obj = DXIBranch() 
```

Constructor
-------------
```python
class DXIBranch:
    """
    All Self Service Branch Operations
    """

    def __init__(
        self,
        engine=DXIBranchConstants.ENGINE_ID,
        log_file_path=DXIBranchConstants.LOG_FILE_PATH,
        config_file=DXIBranchConstants.CONFIG,
        poll=DXIBranchConstants.POLL,
        single_thread=DXIBranchConstants.SINGLE_THREAD,
        parallel=DXIBranchConstants.PARALLEL,
        action=DXIBranchConstants.ACTION,
        module_name=DXIBranchConstants.MODULE_NAME,
    )
```
  
###activate
Activates a self service branch

####Signature
```python
def activate(self, branch_name, container_name=None)
```

####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
branch_name | str |  Name of the branch to create | None 
container_name | str | Name of the SS Container | None 

###create
Creates a self service branch

####Signature
```python
def create(self, branch_name, container_name, template_name=None, bookmark_name=None, timestamp=None):
```

####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
branch_name | str |  Name of the branch to create | None 
container_name | str | Name of the SS Container | None 
template_name | str |  Name of the SS template | None 
bookmark_name | str | Bookmark to create branch | None 
timestamp | str |  Timestamp to create branch | None 

###delete
Delete a branch by name

####Signature
```python
def delete(self, branch_name):
```

####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
branch_name | str |  Name of the branch to create | None 

###list 
List all branches on an engine

####Signature
```python
def list(self):
```