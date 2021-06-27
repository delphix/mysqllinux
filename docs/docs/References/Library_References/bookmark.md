# DXIBookmark

Bookmarks (Self Service Container Bookmark) are a way to mark and name a particular moment of 
data on a timeline of a Self Service Container.   
You can restore the active branch's timeline to the moment of data marked with a bookmark.
This class provides methods to trigger some of the most commonly used bookmark related operations.


How to import
------------- 
```python
from dxi.bookmark.dxi_bookmark import DXIBookmark
from dxi.bookmark.dxi_bookmark import BookmarkConstants
```

Create object
-------------
```
   obj = DXIBookmark() 
```

Constructor
-------------
```python
class DXIBookmark:
    """
    Delphix Integration class for Bookmark Operations

    This class contains all methods to perform Delphix \
    Self Service Bookmark Operations
    """
    def __init__(
        self,
        engine=BookmarkConstants.ENGINE_ID,
        log_file_path=BookmarkConstants.LOG_FILE_PATH,
        config_file=BookmarkConstants.CONFIG,
        poll=BookmarkConstants.POLL,
        single_thread=BookmarkConstants.SINGLE_THREAD,
        parallel=BookmarkConstants.PARALLEL,
        action=BookmarkConstants.ACTION,
        module_name=BookmarkConstants.MODULE_NAME,
    ):
```
  
###create
Create a new bookmark

####Signature
```python
def create(self,bookmark_name, container_name, template_name, branch_name=None, timestamp=None, expires=None, tags=None, description=None,)
```

####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
bookmark_name | str | Name of the bookmark to create | None 
container_name | str | Name of the container to create the bookmark| None 
template_name | str | Name of the template to create the bookmark | None 
branch_name | str | If bookmark is not unique in a container| None 
timestamp | str | Timestamp to create the bookmark.| None 
expires | str | Set bookmark expiration time. Format "%Y-%m-%dT%H:%M:%S"| None 
tags | str |Tags to set on the bookmark| None 
description | str | Description for the bookmark| None 



###delete 
 Delete a bookmark using bookmark name

####Signature
```python
def delete(self, bookmark_name)
```

####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
bookmark_name | str | Name of the bookmark to delete | None 

###list 
 List all Bookmarks on an engine

####Signature
```python
def list(self, tags=None)
```

####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
tags | str | Tags to filter the bookmark names | None 

###share
Share a bookmark by name

####Signature
```python
def share(self, bookmark_name)
```

####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
bookmark_name | str | Name of the bookmark to delete | None 

###unshare
UnShare a bookmark by name

####Signature
```python
def unshare(self, bookmark_name)
```

#### Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
bookmark_name | str | Name of the bookmark to delete | None 

###update 
Updates a bookmark using a bookmark name

####Signature
```python
def update(self,bookmark_name,tags=None,expires=None,new_bookmark_name=None,description=None,)
```

####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
bookmark_name | str | Name of the bookmark to update | None 
tags | str | If updating tags, provide new tags. All existing tags on the bookmark will be replaced with new tags| None 
expires | str | If updating expiration, provide new expiration date-time 'Format: "%Y-%m-%dT%H:%M:%S | None 
new_bookmark_name | str | If updating bookmark name, provide new name| None 
description | str | If updating description, provide new description.| None 