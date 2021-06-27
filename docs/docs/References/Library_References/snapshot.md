# DXISnapshot

Snapshots represent points in time where a sync operation has occurred on either a dSource or VDB.
This class provides methods for commonly used snapshot related operations.

How to import
-------------
 
```python
from dxi.snapshot.dxi_snapshot import DXISnapshot
from dxi.snapshot.dxi_snapshot import SnapshotConstants
```

Create object
-------------
```
   obj = DXISnapshot() 
```

Constructor
-------------
```python
class DXISnapshot:
    """
    Create a snapshot a dSource or VDB
    """
    def __init__(
        self,
        name=SnapshotConstants.NAME,
        group=SnapshotConstants.GROUP,
        parallel=SnapshotConstants.PARALLEL,
        engine=SnapshotConstants.ENGINE_ID,
        poll=SnapshotConstants.POLL,
        config=SnapshotConstants.CONFIG,
        log_file_path=SnapshotConstants.LOG_FILE_PATH,
        all_dbs=SnapshotConstants.ALL_DBS,
        single_thread=SnapshotConstants.SINGLE_THREAD,
    )
```

Methods
--------
Methods correspond to operations you can perform on the snapshot of dSource or VDB.   

###create_snapshot 
To take a snapshot of a dsource, vdb or vfile.

#### Signature
```python
def create(self, use_recent_backup=False, create_backup=False, backup_file=None):
    
```

#### Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
use_recent_backup | bool | Snapshot using "Most Recent backup" | False 
create_backup | bool | Create and ingest a new Sybase backup or copy-only MS SQL backup | False 
backup_file | str | Name of the specific ASE Sybase backup file(s) | None 


