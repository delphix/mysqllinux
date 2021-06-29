# Troubleshooting

If you run into an error while using the MySQL plugin and have an exit code in the error, 
refer to [ExitCodes](/References/ExitCodes/index.html) for further information. 

## Logs

There are 2 sets of logs for the MySQL plugin

1. Plugin Logs
   
    Plugin logs are part of the Delphix Engine. Refer to [How to Retrieve Logs] (https://developer.delphix.com/References/Logging/#how-to-retrieve-logs) 
    to find out how to get the Delphix Plugin Logs. 
   
2. MySQL Shell Operation Logs
   
    When the plugin performs certain operations ( such as Take backup, Link, Provision etc), 
    logs are written to log files on the staging or target host under the *Delphix Toolkit* directory

    Following are the logs to review


   
    - delphix_mysql_debug.log 
    - delphix_mysql_info.log
    - delphix_mysql_error.log