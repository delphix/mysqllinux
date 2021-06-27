# Environment

An Environment in Delphix is a Windows/ Linux / Unix Host that has been linked to Delphix. 
An Environment may be a Source Host, Staging Host or Target Host

dxi provides commands to trigger some of the most commonly used environment related operations

###Usage
Every dxi cli command has 4 sections as shown below  

-   dxi : The main CLI  
-   command : Indicates the Delphix object you will be working on. In this case,'environment'   
-   Operation : The operation that you are performing on the Delphix object
-   Options: Required and optional parameters for the operation

```commandline 
   dxi environment <operation> [options]
```

### Operations
Operations correspond to operations you can perform on the engine.   
The available actions on an environment are 

- add - Adds an environment
- delete - Deletes an environment
- updateHost - Updates the IP address on an existing environment
- refresh - Refreshes an existing environment
- list - Lists all environments 

### Options

Options are additional parameters that you can pass to a dxi command in order to modify the behavior of the operation.
Some options are required, while others are not. The required options will be marked as [required] in the help information for an action.

!!! tip "Options"
    Detailed information on options coming soon. To view all options for an operation, run the following.
    ```bash
       dxi environment <operation> --help
    ```

### Access Help Information
At every step, you can access the help information for a dxi command as follows

#### Access help info for the dxi environment command
```commandline 
   dxi environment --help
```
#### Access help info for a specific dxi environment action
```commandline 
   dxi environment <operation> --help
```