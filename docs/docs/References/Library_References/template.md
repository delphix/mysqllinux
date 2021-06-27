# DXITemplate

A Template (Self Service Template) refers to a blueprint to create Self Service containers in Delphix.
It provides methods for all Self Service Template related operations.

How to import
------------- 
```python
from dxi.template.dxi_template import DXITemplate
from dxi.template.dxi_template import DXITemplateConstants
```

Create object
-------------
```
   obj = DXITemplate() 
```

Constructor
-------------
```python
class DXITemplate:
    """
    Class for Self Service Template Operations
    """

    def __init__(
        self,
        engine=DXITemplateConstants.ENGINE_ID,
        single_thread=DXITemplateConstants.SINGLE_THREAD,
        config=DXITemplateConstants.CONFIG,
        log_file_path=DXITemplateConstants.LOG_FILE_PATH,
        poll=DXITemplateConstants.POLL,
        action=DXITemplateConstants.ACTION,
    ):
```

Methods
-------------
Method for all Self Service Template related operations.  

###create 
Create a template on an engine

####Signature
```python
def create(self, template_name, dbnames)
```

####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
template_name | str |Name of the template to create| None 
dbnames | str | List of datasource names, separated by ":' (Sample oraclesrc1:sqlsrc1 ) | None 

###list 
List all templates on an engine

####Signature
```python
def list(self)
```

###delete 
Delete a template from an engine

#### Signature
```python
def delete(self, template_name)
```

####Arguments
Argument | Type | Description | Default    
-------- | ---- | ----------- | -------- 
template_name | str |Name of the template to delete| None 
