# Container

A Container (Self Service Container) in Delphix refers to set of Virtual Datasets 
that are grouped together and can be operated on as a single unit through Delphix Self Service

dxi provides commands to trigger some of the most commonly used container related operations

###Usage
Every dxi cli command has 4 sections as shown below

-   dxi : The main CLI
-   command : Indicates the Delphix object you will be working on. In this case,'container'.
-   Operation : The operation that you are performing on the Delphix object
-   Options: Required and Optional parameters for the operation

```commandline 
   dxi container <operation> [options]
```

### Operations
Operations correspond to operations you can perform on the engine.   
The available operations on an container are

- create - Create a container
- update - Update a container
- delete - Deletes a container
- connection-info -   Get connection info of a container
- refresh - Refresh a container
- restore - Restore a container
- reset - Reset a container  
- list - Lists all templates on an engine.

### Options

Options are additional parameters that you can pass to a dxi command in order to modify the behavior of the operation.
Some options are required, while others are not. The required options will be marked as [required] in the help information for an action.

!!! tip "Options"
     Detailed information on options coming soon. To view all options for an operation, run the following.
     ```bash
     dxi container <operation> --help
     ```

### Access Help Information
At every step, you can access the help information for a dxi command as follows

#### Access help info for the dxi environment command
```commandline 
   dxi container --help
```
#### Access help info for a specific dxi environment action
```commandline 
   dxi container <operation> --help
```