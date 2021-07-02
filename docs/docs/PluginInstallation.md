# Plugin Installation


## Prerequisites


-   Delphix Engine of version 6.0.x
-   Install MySQL Binaries on source, staging, and target servers

## Installing the MySQL Plugin

### Method1: Using GUI

1. Click on **Manage** (present on top-left of this page) and then **Plugins**.  
   
      ![Screenshot](./image/image2.png)


2. Click on **+** icon.  
   
      ![Screenshot](./image/image3.png)


3. Click on **Upload** a plugin.  
   
      ![Screenshot](./image/image4.png)


4. Select the `build(artifacts.json)` from your device.   
   
      ![Screenshot](./image/image5.png)


5. Click on **close** button.  
   
      ![Screenshot](./image/Image6.png)


6. See the plugin version in **Plugins** section.  
   
      ![Screenshot](./image/Image7.png)


### Method2: Using dvp command

`dvp upload -e <Delphix_Engine_Name> -u <username> --password <password>`

Delphix Engine's documentation on installing plugins: 
[PluginManagement](https://docs.delphix.com/docs/datasets/unstructured-files-and-app-data/delphix-engine-plugin-management).