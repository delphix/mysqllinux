# DXIUser

Delphix Virtualization Engine supports 3 different types of users
- Admin User
- Standrad Engine User
  _ Self-Service User

Read more about Delphix Users [here](https://docs.delphix.com/docs/configuration/user-and-authentication-management/users-and-groups)


How to import
------------- 
```python
from dxi.user.dxi_user import DXIUser
from dxi.user.dxi_user import DXIUserConstants
```

Create object
-------------
```
   obj = DXIUser() 
```

Constructor
-------------
```python
class DXIUser:
    """
    Class to operate on Delphix User objects.
    """

    def __init__(
        self,
        engine=DXIUserConstants.ENGINE_ID,
        single_thread=DXIUserConstants.SINGLE_THREAD,
        config=DXIUserConstants.CONFIG,
        log_file_path=DXIUserConstants.LOG_FILE_PATH,
        poll=DXIUserConstants.POLL,
        debug=False,
    ):
```

Methods
-------------
Method for all User related operations.  

###create 
Create a User on a Delphix Virtualization Engine

####Signature
```python
    def create(
        self,
        user_name,
        user_password,
        first_name,
        last_name,
        email_address
):
```

####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
user_name | str |Name of the user to create  | None
user_password | str | Password for the new user | None
first_name | str | First Name of the new user | None
last_name | str | Last Name for the new user | None
email_address | str | Email Address for the new user | None

###list 
List all Delphix Virtualization Users on an engine

####Signature
```python
def list(self)
```

###delete 
Delete a Delphix Virtualization Engine user.

#### Signature
```python
def delete(self, user_name)
```

####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
user_name | str |Name of the user to delete| None

###update
Update a Delphix Virtualization Engine user.

#### Signature
```python
def update(
        self
        user_name,
        first_name=None,
        last_name=None,
        email_address=None,
        current_password=None,
        new_password=None
)
```

####Arguments
Argument | Type | Description | Default
-------- | ---- | ----------- | -------- 
user_name | str |Name of the user to update  | None
current_password | str | Current password for the user | None
new_password | str | New password for the user | None
first_name | str | First Name of the user | None
last_name | str | Last Name for the user | None
email_address | str | Email Address for the user | None

