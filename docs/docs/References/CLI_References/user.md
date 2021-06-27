# User

Delphix Virtualization Engine supports 3 different types of users 
- Admin User
- Standrad Engine User
_ Self-Service User

Read more about Delphix Users [here](https://docs.delphix.com/docs/configuration/user-and-authentication-management/users-and-groups)

dxi provides commands to trigger some of the most common User related operations

###Usage
Every dxi cli command has 4 sections as shown below

-   dxi : The main CLI
-   command : Indicates the Delphix object you will be working on. In this case,'user'.
-   Operation : The operation that you are performing on the Delphix object
-   Options: Required and Optional parameters for the operation

```commandline 
   dxi user <operation> [options]
```

### Operations
Operations correspond to operations you can perform on the engine.   
The available operations on a user are

- create - Create a Delphix Virtualization Engine User
- delete - Deletes a Delphix Virtualization Engine User
- list - Lists all a Delphix Virtualization Engine Users
- update - Update a Delphix Virtualization Engine User

### Options

Options are additional parameters that you can pass to a dxi command in order to modify the behavior of the operation.
Some options are required, while others are not. The required options will be marked as [required] in the help information for an action.

!!! tip "Options"
      Detailed information on options coming soon. To view all options for an operation, run the following.
      ```bash
      dxi user <operation> --help
      ```

### Access Help Information
At every step, you can access the help information for a dxi command as follows

#### Access help info for the dxi environment command
```commandline 
   dxi user --help
```
#### Access help info for a specific dxi environment action
```commandline 
   dxi user <operation> --help
```