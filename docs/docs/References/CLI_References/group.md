# Group

Groups in Delphix Virtualization Engine are used to group one or more datasets. 
You can think of groups as folders to organize your dSources, VDBs and vFiles.

dxi provides commands to trigger some of the most commonly used Group related operations

###Usage
Every dxi cli command has 4 sections as shown below

-   dxi : The main CLI
-   command : Indicates the Delphix object you will be working on. In this case,'group'.
-   Operation : The operation that you are performing on the Delphix object
-   Options: Required and Optional parameters for the operation

```commandline 
   dxi group <operation> [options]
```

### Operations
Operations correspond to operations you can perform on the engine.   
The available operations on a group are

- create - Create a group
- delete - Deletes a group
- list - Lists all groups on a Delphix Engine.
- update - Update a group.

### Options

Options are additional parameters that you can pass to a dxi command in order to modify the behavior of the operation.
Some options are required, while others are not. The required options will be marked as [required] in the help information for an action.

!!! tip "Options"
      Detailed information on options coming soon. To view all options for an operation, run the following.
      ```bash
      dxi group <operation> --help
      ```

### Access Help Information
At every step, you can access the help information for a dxi command as follows

#### Access help info for the dxi environment command
```commandline 
   dxi group --help
```
#### Access help info for a specific dxi environment action
```commandline 
   dxi group <operation> --help
```