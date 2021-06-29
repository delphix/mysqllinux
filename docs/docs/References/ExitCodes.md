# Plugin Exit Codes

Detailed below are the exit codes that the MySQL 
Plugin throws if an error occurs. 


## Exit Codes
Code | Description | Possible Reason
-------- | ----------- | -----------
1 | General Error | Check logs
2 | General Error | Check logs
3 | Unable to start MySQL | 1. Delphix user does not have the necessary permissions on the host  <br/> 2. Mount location provided is  in use <br/> 3. Database credentials provided are not accurate <br/> 4. Invalid serverid <br/> 5. Provided port is not in use
4 | Missing config file | A *my.cnf* file was not provided and Delphix was unable to create one. 
5 | Unable to change *root* password | Delphix was unable to change the password for the root user after creating the staging db.<br/> Please check logs. 
6 | Unable to restore backup | Delphix was unable to restore the full backup into staging db. Please check logs.
7 | Connect failure post restore  | Delphix is unable to connect to staging db after backup is restored. <br/> 1. The Source DB username and password provided may be incorrect <br/>2. The MySQL Database did not restart after the restore. <br/> Check logs for more information on the error.
8 | Delphix backup failure | Delphix could not take a source db backup. <br/> 1. Staging Host may not be able to connect to Source Host <br/> 2. Source DB credentials may be incorrect <br/> 3. Source DB user may not have the required permissions <br/>4. Databases provided in the list may not be present on the source MySQL instance. <br/> Check logs for more information on the error.
9 | Customer backup failure | There was an issue with the customer provided backup. 1. Backup location may not exist. <br/> 2. The backup file may not exist <br/> 3. Backup file may be empty.<br/>Check logs for more information on the error.
10 | Invalid binary path  | *mysql* was not found under the provided installation directory.
11 | Connect failure after restart  | In Backup Ingestion Mode, the Delphix source user could not connect to the MySQL instance after reboot. </br> Check logs for more information on the error.
12 | Unable to create user  | In Backup Ingestion Mode, there was an error while creating the delphix user after staging db was initialized. </br> Check logs for more information on the error.

