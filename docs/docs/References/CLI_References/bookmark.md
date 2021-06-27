# Bookmark

Bookmarks (Self Service Container Bookmark) are a way to mark and name a particular moment of 
data on a timeline of a Self Service Container.   
You can restore the active branch's timeline to the moment of data marked with a bookmark

dxi provides commands to trigger some of the most commonly used bookmark related operations

###Usage
Every dxi cli command has 4 sections as shown below

-   dxi : The main CLI
-   command : Indicates the Delphix object you will be working on. In this case,'bookmark'.
-   Operation : The operation that you are performing on the Delphix object
-   Options: Required and Optional parameters for the operation

```commandline 
   dxi bookmark <operation> [options]
```

### Operations
Operations correspond to operations you can perform on the engine.   
The available operations on an bookmark are

- create - Create a bookmark
- update - Update a bookmark
- share - Update a bookmark
- unshare - Update a bookmark  
- delete - Deletes a bookmark
- list - Lists all bookmarkes on an engine.

### Options

Options are additional parameters that you can pass to a dxi command in order to modify the behavior of the operation.
Some options are required, while others are not. The required options will be marked as [required] in the help information for an action.

!!! tip "Options"
      Detailed information on options coming soon. To view all options for an operation, run the following.
      ```bash
      dxi bookmark <operation> --help
      ```

### Access Help Information
At every step, you can access the help information for a dxi command as follows

#### Access help info for the dxi environment command
```commandline 
   dxi bookmark --help
```
#### Access help info for a specific dxi environment action
```commandline 
   dxi bookmark <operation> --help
```