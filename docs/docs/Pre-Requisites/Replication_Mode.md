# Replication

Given below are the pre-requisites for MySQL virtualization when using Replication mode.

### Source Environment Requirements
    
 Source environment is where the source MySQL databases are running. 

#### Connectivity
 - Delphix staging user must be able to connect to source environment from staging and take a backup of the source database(s) using the *mysqldump* utility.

#### Source DB User
- A Source DB user with the following permissions. 


    - Can connect to the source database from staging host as well as locally
      ```jql
        mysql>CREATE USER 'delphix_os'@'<staging_host>' IDENTIFIED BY 'delphix_user_passwd';
      ```  
      ```jql       
        mysql>CREATE USER 'delphix_os'@'localhost' IDENTIFIED BY 'delphix_user_passwd';
      ```    
  
    - Has at the minimum, the following permissions on the source database(s).
  
        *SELECT, SHUTDOWN, SUPER, RELOAD ,SHOW VIEW, EVENT, TRIGGER, REPLICATION CLIENT,REPLICATION SLAVE*
      ```jql    
        mysql>GRANT SELECT, SHUTDOWN, SUPER, RELOAD ,SHOW VIEW, EVENT, TRIGGER, REPLICATION CLIENT,REPLICATION SLAVE on *.* to 'delphix_os'@'staging-host';
      ```
      ```jql          
        mysql>GRANT SELECT, SHUTDOWN, SUPER, RELOAD ,SHOW VIEW, EVENT, TRIGGER on *.* to 'delphix_os'@'localhost';
      ```  
      
        You can also grant more permissive privileges  
        ```jql 
         mysql>GRANT ALL PRIVILEGES ON *.* TO 'user'@'%';
        ```  

    !!! note
        Remember, this is the user that Delphix uses to manage the Staging database. 
        So, it is recommended that you create a dedicated source db user for Delphix with the privileges 
        mentioned above.
  
        At present, the plugin uses the same source db user for backup and replication.
        

#### Binary Logging 
- In order to set up replication, binary logging should be enabled on the source database.
  You can check the status of binary logging as follows 
  
    ```jql
    mysql> SHOW VARIABLES LIKE 'log_bin';
    ```
  If binary logging is enabled, you should see the following status
    ```commandline
        +---------------+-------+
        | Variable_name | Value |
        +---------------+-------+
        | log_bin       | ON    |
        +---------------+-------+
    ```

#### Server-Id
The source database must have a non zero server-id. 

### Staging Environment Requirements

#### Staging OS User

This is a typical Delphix OS staging user. 
Key requirements for this user are given below. 

Please refer to Delphix Docs for more detailed requirements.

- A Delphix OS user with the elevated permissions to run *ps, mount, umount, mkdir, rmdir* 
  commands without requiring a password 

    <div class="code_box_outer">
        <div class="code_box_title">
              <span class="code_title">*/etc/sudoers*</span>
        </div>
        <div>
            ```groovy hl_lines="6"
                Defaults:delphix_os !requiretty
                delphix_os ALL=NOPASSWD: \ 
                /bin/mount, /bin/umount, /bin/mkdir, /bin/rmdir, /bin/ps
            ```
        </div>
    </div>
  
 - Delphix OS user should be in the same primary and secondary groups as mysql user ( or the MySQL binary owner )
 - Delphix OS user must have execute access on all files within MySQL installation folder - Min permission level 775 recommended.

#### Storage
 - Staging Host must have enough storage space to hold the source backup file. 
 - Empty folder on staging host to hold delphix toolkit [ approximate 2GB free space ]

#### MySQL Version & Configuration
- MySQL Binary version must match the version on the source database(s)
  
- <span class="code_title">[Recommended] </span>
  As every  organization's MySQL configuration is different, 
  Delphix expects a starter *my.cnf* file to be present in Delphix Toolkit Directory when creating a staging database.
  Delphix will use this *my.cnf* file and modify it as per the configuration provided during the the dsource creation process. 
  
    This is recommended to reduce the possibility of errors while restoring the backup from the source database.


### Target Environment Requirements

#### Target OS User

This is a typical Delphix OS target user.
Key requirements for this user are given below.

Please refer to Delphix Docs for more detailed requirements.

- A Delphix OS user with the elevated permissions to run *ps, mount, umount, mkdir, rmdir*
  commands without requiring a password

    <div class="code_box_outer">
        <div class="code_box_title">
              <span class="code_title">*/etc/sudoers*</span>
        </div>
        <div>
            ```groovy hl_lines="6"
                Defaults:delphix_os !requiretty
                delphix_os ALL=NOPASSWD: \ 
                /bin/mount, /bin/umount, /bin/mkdir, /bin/rmdir, /bin/ps
            ```
        </div>
    </div>

- Delphix OS user should be in the same primary and secondary groups as mysql user ( or the MySQL binary owner )
- Delphix OS user must have execute access on all files within MySQL installation folder - Min permission level 775 recommended.


Done, What's Next?
----------------
Alright, we've taken care of all the pre-requisites. Next step - Install the plugin.   

