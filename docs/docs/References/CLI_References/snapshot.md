# Snapshot

Snapshots represent points in time where a sync operation has occurred on either a dSource or VDB

dxi provides commands to trigger some of the most commonly used snapshot related operations

###Usage
Every dxi cli command has 4 sections as shown below

-   dxi : The main CLI
-   command : Indicates the Delphix object you will be working on. In this case,'snapshot'.
-   Operation : The operation that you are performing on the Delphix object
-   Options: Required and Optional parameters for the operation

```commandline 
   dxi snapshot <operation> [options]
```

### Operations
Operations correspond to operations you can perform on the engine.   
The available actions on an snapshot are

- create - Creates a snapshot on a dataset.

### Options

Options are additional parameters that you can pass to a dxi command in order to modify the behavior of the operation.
Some options are required, while others are not. The required options will be marked as [required] in the help information for an action.

!!! tip "Options"
     Detailed information on options coming soon. To view all options for an operation, run the following.
     ```bash
     dxi snapshot <operation> --help
     ```

### Access Help Information
At every step, you can access the help information for a dxi command as follows

#### Access help info for the dxi environment command
```commandline 
   dxi snapshot --help
```
#### Access help info for a specific dxi environment action
```commandline 
   dxi snapshot <operation> --help
```