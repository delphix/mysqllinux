# Branch

A branch (Self Service Container Branch) allows you create 
multiple versions of your data within a container, just as you would do with code.

dxi provides commands to trigger some of the most commonly used branch related operations

###Usage
Every dxi cli command has 4 sections as shown below

-   dxi : The main CLI
-   command : Indicates the Delphix object you will be working on. In this case,'branch'.
-   Operation : The operation that you are performing on the Delphix object
-   Options: Required and Optional parameters for the operation

```commandline 
   dxi branch <operation> [options]
```

### Operations
Operations correspond to operations you can perform on the engine.   
The available operations on an branch are

- create - Create a branch
- activate - Activate a branch
- delete - Deletes a branch
- list - Lists all branches on an engine.

### Options

Options are additional parameters that you can pass to a dxi command in order to modify the behavior of the operation.
Some options are required, while others are not. The required options will be marked as [required] in the help information for an action.

!!! tip "Options"
     Detailed information on options coming soon. To view all options for an operation, run the following.
     ```bash
     dxi branch <operation> --help
     ```

### Access Help Information
At every step, you can access the help information for a dxi command as follows

#### Access help info for the dxi environment command
```commandline 
   dxi branch --help
```
#### Access help info for a specific dxi environment action
```commandline 
   dxi branch <operation> --help
```