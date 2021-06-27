# Database

A Database refers to any dataset in Delphix.  
A Database can be a source (dsource) or virtual (vdb or vfiles) database.

dxi provides commands to trigger some of the most commonly used database related operations.  

###Usage
Every dxi cli command has 4 sections as shown below

-   dxi: The main CLI
-   command: Indicates the Delphix object you will be working on. In this case,'database'.
-   Operation: The operation that you are performing on the Delphix object
-   Options: Required and Optional parameters for the operation

```commandline 
   dxi database <operation> [options]
```

### Operations
Operations correspond to operations you can perform on a Delphix Engine.   
The  available actions on a database are

- delete - Delete a Delphix dSource or VDB.
- disable - Disable a virtual dataset by name and group (optional).
- enable - Enable a virtual dataset by name and group (optional).
- ingest - Ingest source data to create a dsource.
- list - List all datasets on an engine.
- provision - Provision Delphix Virtual Databases and vFiles.
- refresh - Refresh a Delphix VDB or vFile.
- rewind - Rewind a VDB or vFile.
- start - Starts a virtual dataset by name and group (optional).
- stop - Stop a virtual dataset by name and group (optional).

######*Support for additional databases and operations will come soon.

### Options

Options are additional parameters that you can pass to a dxi command in order to modify the behavior of the operation.
Some options are required, while others are not. The required options will be marked as [required] in the help information for an action.

!!! tip "Options"
     Detailed information on options coming soon. To view all options for an operation, run the following.
     ```bash
     dxi database <operation> --help
     ```

### Access Help Information
At every step, you can access the help information for a dxi command as follows

#### Access help info for the dxi environment command
```commandline 
   dxi database --help
```
#### Access help info for a specific dxi environment action
```commandline 
   dxi database <operation> --help
```