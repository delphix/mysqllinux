# Overview

MySQL plugin has been developed to ingest and virtualize MySQL data sources using Delphix.

What does MySQL plugin do? 
--------------------------
The Delphix MySQL Plugin can virtualize a single instance MySQL database and create 
multiple virtual copies as required. 

There are two modes of operation of the plugin based on how the MySQL dSource is created 
and kept in-sync with source database.

### Replication

In the Replication mode, Delphix uses MySQL's built-in replication technology to keep 
the Delphix dSource in-sync with the MySQL source databases.

Creation of the dSource requires a full backup of the source database(s) and there are
two options to providing this backup. 

1. Delphix Managed Backup 
   
    In this option, Delphix is provided with the required information to take 
    a full backup of the source database.
    
2. User Provided Backup 
   
    In this option, user provides Delphix with an existing full backup. 
    Delphix initializes the staging database using the full backup and configures the 
   staging database as a replicated slave of the source database. 
    MySQL Replication keeps the data in the staging database in-sync with the source. 
   
### Manual Ingestion
In the Manual Ingestion mode, the data in Delphix dSource is managed manually by the end users.
Delphix creates a seed MySQL staging database which can be managed via Delphix. 
The end user assumes the responsibility of keeping the data in the staging 
database in-sync with the source database. 

Where to Start?
--------------
By now, you must have an overall idea of what is possible with the MySQL plugin. 
Before you can get started with virtualizing your MySQL databases, 
there are some pre-requisites you need to take care of. 
Please visit the [Pre-Requisites](/Pre-Requisites/General/index.html) page for more details. 

Questions?
----------------
If you have questions, bugs or feature requests reach out to us via the [MySQL Github](https://github.com/delphix/mysqllinux/) or 
at [Delphix Community Portal](https://community.delphix.com/home)