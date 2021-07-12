#
# Copyright (c) 2020 by Delphix. All rights reserved.
#

#######################################################################################################################
# This module contains all functions invoked by the main plugin() module. 
# All virtual operations are moved to Python already. 
# Staging/Linking operations are still in hybrid code
#######################################################################################################################
import pkgutil
import logging
import random
import time
import sys
import json
import re
import os
from datetime import datetime
from common import utils,constants
#from dboperations import dboperations
from common.commands import CommandFactory
from dlpx.virtualization.platform import Status
from dlpx.virtualization import libs
from dlpx.virtualization.platform.exceptions import UserError
from customexceptions.plugin_exceptions import RepositoryDiscoveryError,LinkingException,VirtualException
from customexceptions.database_exceptions import (
    StagingStartupException,
    StagingShutdownException,
    ReplicationSetupException,
    SourceBackupException,
    MySQLShutdownException,
    MySQLStartupException
)
from dlpx.virtualization.platform import Mount, MountSpecification, Plugin, Status
#from common import exceptions
from generated.definitions import (
    RepositoryDefinition,
    SourceConfigDefinition,
    SnapshotDefinition,
)

logger = logging.getLogger(__name__)

##################################################
# Find Repository Information on Host
# Format: Python
##################################################
def find_mysql_binaries(connection):
    logger.debug("operations.find_mysql_binaries()")
    baseName=""
    version=""
    dirName=""
    prettyName=""
    try:
        bashresult = runbash(connection,CommandFactory.find_binary_path(),None)
        repoList=bashresult.stdout.strip()
        stderr=bashresult.stderr.strip()
        exitcode=bashresult.exit_code
        logger.debug("find_mysql_binaries>_repoList > \n "+repoList)
        repositories=[]
        if exitcode !=0:
            logger.debug("find_mysql_binaries > exit code > "+str(exitcode))
            raise RepositoryDiscoveryError(stderr)
        elif (repoList =="" or repoList is None ):
            logger.debug("find_mysql_binaries > No MySQL repositories found")
        else:
            for repoPath in repoList.splitlines():
                logger.debug("Parsing repository at "+repoPath)
                if not utils.validate_repository(repoPath):
                    logger.debug("Invalid repository path. Skipping")
                    continue
                baseName=os.path.basename(repoPath)
                dirName=os.path.dirname(repoPath)
                bashresult=runbash(connection,CommandFactory.get_version(repoPath),None)
                versionStr=bashresult.stdout.strip()
                versionArr=versionStr.split(" ")
                version=versionArr[3]
                if (version !="" and baseName =="mysqld"):
                    prettyName= versionStr[versionStr.index("(MySQL"):len(versionStr)]
                    prettyName= prettyName+" {}".format(version)
                    repository = RepositoryDefinition(
                                    name=prettyName,
                                    install_path=dirName,
                                    version=version
                                )
                    repositories.append(repository)
    except RepositoryDiscoveryError as err:
        raise RepositoryDiscoveryError(err.message).to_user_error(), None, sys.exc_info()[2]
    except Exception as err:
        raise
    return repositories

##################################################
# Function to start Staging DB
# Format: Hybrid ( Python calls Shell Script )
##################################################
def start_staging(staged_source, repository, source_config):
    logger.debug("plugin-operations > Starting Staged DB")
    binary_path=staged_source.staged_connection.environment.host.binary_path
    staging_ip="localhost"
    stagingConn=build_lua_connect_string(staged_source.parameters.source_user, staging_ip)
    logger.debug("Binary Path in start_staging:"+binary_path)
    if staged_source.parameters.d_source_type == "Replication": 
        logger.debug("dSourceType is Replication")
        library_script=pkgutil.get_data('resources','library.sh')
        mount_path=staged_source.parameters.mount_path
        if staged_source.parameters.log_sync == True:
            log_sync = "true"
        else:
            log_sync = "false"
        logger.debug("LogSync> "+log_sync)
        environment_vars={
            "DLPX_LIBRARY_SOURCE" : library_script,
            "DLPX_BIN" : binary_path,
            "MYSQLD":repository.install_path,
            "STAGINGSERVERID":staged_source.parameters.server_id,
            "STAGINGPORT":staged_source.parameters.staging_port,
            "STAGINGCONN":stagingConn,
            "STAGINGPASS":staged_source.parameters.staging_pass,
            "LOGSYNC":log_sync,
            "STAGINGDATADIR":mount_path
        }        
        start_staging_script = pkgutil.get_data('resources', 'startStagedDB.sh')
        result = libs.run_bash(staged_source.staged_connection, start_staging_script,environment_vars,check=True)
        output = result.stdout.strip()
        error = result.stderr.strip()
        logger.debug("output:"+output)
        logger.debug("error:"+error)
        exit_code = result.exit_code
        if exit_code !=0:
            logger.debug("There was an error> "+error)
            raise LinkingException("Exception while Starting Stage:"+error)
        else:
            logger.debug("Start Staging - Successful")
    #elif staged_source.parameters.d_source_type == "Manual Backup Ingestion":
    else:
        logger.debug("dSourceType is Manual Backup Ingestion.")
        library_script=pkgutil.get_data('resources','library.sh')
        mount_path=staged_source.parameters.mount_path
        environment_vars={
            "DLPX_LIBRARY_SOURCE" : library_script,
            "DLPX_BIN" : binary_path,
            "MYSQLD":repository.install_path,
            "STAGINGSERVERID":staged_source.parameters.server_id,
            "STAGINGPORT":staged_source.parameters.staging_port,
            "STAGINGCONN":stagingConn,
            "STAGINGPASS":staged_source.parameters.staging_pass,
            "STAGINGDATADIR":mount_path
        }        
        start_staging_script = pkgutil.get_data('resources', 'startStagedDB.sh')
        result = libs.run_bash(staged_source.staged_connection, start_staging_script,environment_vars,check=True)
        output = result.stdout.strip()
        error = result.stderr.strip()
        logger.debug("output:"+output)
        logger.debug("error:"+error)
        exit_code = result.exit_code
        if exit_code !=0:
            logger.debug("Error is : "+error)
            raise LinkingException("Exception while Starting Stage:"+error)
        else:
            logger.debug("Start Staging - Successful")        

##################################################
# Function to Stop Staging DB
# Format: Hybrid ( Python calls Shell Script )
##################################################
def stop_staging(staged_source, repository, source_config):
    logger.debug("plugin_operations.stop_staging > Stopping Staged DB")
    staging_ip="localhost"
    stagingConn=build_lua_connect_string(staged_source.parameters.source_user,staging_ip)
    if staged_source.parameters.d_source_type == "Replication": 
        library_script=pkgutil.get_data('resources','library.sh')
        binary_path=staged_source.staged_connection.environment.host.binary_path
        environment_vars={
            "DLPX_LIBRARY_SOURCE": library_script,
            "DLPX_BIN": binary_path,
            "MYSQLD": repository.install_path,
            "STAGINGPORT":staged_source.parameters.staging_port,
            "STAGINGCONN":stagingConn,
            "STAGINGPASS":staged_source.parameters.staging_pass
        }
        stop_staging_script = pkgutil.get_data('resources', 'stopStagedDB.sh')
        result = libs.run_bash(staged_source.staged_connection, stop_staging_script,environment_vars,check=True)
        output = result.stdout.strip()
        error = result.stderr.strip()
        exit_code = result.exit_code
        if exit_code !=0:
            logger.debug("Error is : "+error)
            raise LinkingException("Exception while stopping staging:"+error)
        else:
            logger.debug("Stop Staging - Successful: "+output)
    elif staged_source.parameters.d_source_type == "Manual Backup Ingestion":
        logger.debug("plugin_operations.stop_staging > Manual Backup Ingestion")
        library_script=pkgutil.get_data('resources','library.sh')
        binary_path=staged_source.staged_connection.environment.host.binary_path
        environment_vars={
            "DLPX_LIBRARY_SOURCE":library_script,
            "DLPX_BIN":binary_path,
            "MYSQLD":repository.install_path,
            "STAGINGPORT":staged_source.parameters.staging_port,
            "STAGINGCONN":stagingConn,
            "STAGINGPASS":staged_source.parameters.staging_pass,
        }
        stop_staging_script = pkgutil.get_data('resources', 'stopStagedDB.sh')
        result = libs.run_bash(staged_source.staged_connection, stop_staging_script,environment_vars,check=True)
        output = result.stdout.strip()
        error = result.stderr.strip()
        exit_code = result.exit_code
        if exit_code !=0:
            logger.debug("Error is : "+error)
            raise LinkingException("Exception while stopping staging:"+error)
        else:
            logger.debug("Stop Staging - Successful: "+output)   
    else :
        logger.debug("dSourceType is Simple Tablespace Backup. ")
        library_script=pkgutil.get_data('resources','library.sh')
        binary_path=staged_source.staged_connection.environment.host.binary_path
        environment_vars={
            "DLPX_LIBRARY_SOURCE":library_script,
            "DLPX_BIN":binary_path,
            "MYSQLD":repository.install_path,
            "STAGINGPORT":staged_source.parameters.staging_port,
            "STAGINGCONN":stagingConn,
            "STAGINGPASS":staged_source.parameters.staging_pass
        }
        stop_staging_script = pkgutil.get_data('resources', 'stopStagedDB.sh')
        result = libs.run_bash(staged_source.staged_connection, stop_staging_script,environment_vars,check=True)
        output = result.stdout.strip()
        error = result.stderr.strip()
        exit_code = result.exit_code
        if exit_code !=0:
            logger.debug("Error is : "+error)
            raise LinkingException("Exception while stopping staging:"+error)
        else:
            logger.debug("Stop Staging - Successful: "+output)


##################################################
# Function to perform pre-snapshot actions
# Format: Hybrid ( Python calls Shell Script )
##################################################

def linked_pre_snapshot(staged_source, repository, source_config, snapshot_parameters):
    logger.debug("plugin_operations.linked_pre_snapshot > Start ")
    dSourceType = staged_source.parameters.d_source_type
    staging_ip = "localhost"

    # Check if performing re-sync
    if int(snapshot_parameters.resync) == 1:
        # Setting defaults
        logsync="true"
        resync_staging_user="root"
        is_delphix_managed=True
        backup_options=""
        aws_rds=""

        if not staged_source.parameters.log_sync:
            logsync="false"
        if staged_source.parameters.aws_rds:
            aws_rds="true"
        #Are backups managed by Delphix?
        backup_path = staged_source.parameters.backup_path
        if backup_path is not None and backup_path.strip()!="":
            is_delphix_managed=False
        logger.debug("Delphix Managed Backups? "+str(is_delphix_managed))

        # Building backup options
        if is_delphix_managed:
            dbs = utils.parse_db_list(staged_source.parameters.database_list)
            logger.debug("List of databases to backup >"+dbs)
            backup_options = utils.create_backup_options(logsync, dbs, logger, aws_rds)
            logger.debug("Backup Options for restore.sh >"+backup_options)

        # Create & Copy Backup file to staging host
        logger.debug("Resyunc found > Performing Resync > Starting with Backup")
        binary_path=staged_source.staged_connection.environment.host.binary_path
        library_script=pkgutil.get_data('resources','library.sh')
        mount_path=staged_source.parameters.mount_path

        # Buiding Connection Strings for Hybrid Code
        sourceConn=build_lua_connect_string(staged_source.parameters.source_user,staged_source.parameters.sourceip)
        stagingConn=build_lua_connect_string(resync_staging_user, staging_ip)

        logger.debug("source_conection > "+sourceConn)
        logger.debug("staging_conection > "+stagingConn)

        # If performing resync on existing db, we must shut down first.
        # If an error occurs, ignore and proceed.
        stop_staging(staged_source, repository, source_config)


        if dSourceType == "Replication": 
            logger.debug("Inside linked_pre_snapshot() > resync () > dSourceType is Replication")
            environment_vars={
                "DLPX_LIBRARY_SOURCE" : library_script,
                "DLPX_BIN" : binary_path,
                "MYSQLD":repository.install_path,
                "MYSQLVER":repository.version,
                "SOURCEDATADIR":source_config.data_dir,
                "SOURCEBASEDIR":source_config.base_dir,
                "SOURCEPORT":source_config.port,
                "SOURCEIP":staged_source.parameters.sourceip,
                "BACKUP_PATH":staged_source.parameters.backup_path,
                "SOURCECONN":sourceConn,
                "SOURCEUSER":staged_source.parameters.source_user,
                "SOURCEPASS":staged_source.parameters.source_pass,
                "REPLICATION_USER":staged_source.parameters.replication_user,
                "REPLICATION_PASS":staged_source.parameters.replication_pass,
                "STAGINGSERVERID":staged_source.parameters.server_id,
                "STAGINGPORT":staged_source.parameters.staging_port,
                "STAGINGCONN":stagingConn,
                "STAGINGPASS":staged_source.parameters.staging_pass,
                "LOGSYNC":logsync,
                "STAGINGDATADIR":mount_path,
                "STAGINGHOSTIP":staging_ip,
                "BACKUP_OPTIONS":backup_options,
                "AWS_SOURCE":aws_rds,
            }
            logger.debug("Taking Source BackUp")
            backup_script = pkgutil.get_data('resources', 'restore.sh')
            result = libs.run_bash(staged_source.staged_connection, backup_script,environment_vars,check=False)
            output = result.stdout.strip()
            std_err = result.stderr.strip()
            exit_code = result.exit_code
            if exit_code !=0:
                logger.debug("Error is : "+std_err)
                logger.debug("There was an error while taking source backup.Check error.log for details.")
                err = utils.process_exit_codes(exit_code,"DBLINK",std_err)
                logger.error(err)
                raise err
            else:
                logger.debug("Pre-Snapshot/Restore successful "+output)   
            logger.debug("Restoring Backup to Stage")
            restore_script = pkgutil.get_data('resources', 'restore_stage.sh')
            result = libs.run_bash(staged_source.staged_connection, restore_script,environment_vars,check=False)
            logger.debug(result)
            output = result.stdout.strip()
            std_err=result.stderr.strip()
            exit_code = result.exit_code
            logger.debug(std_err)
            logger.debug(exit_code)
            if exit_code == 0:
                logger.debug("Creation of Staging DB(Pre-Snapshot) successful."+output)
            else:
                logger.debug("There was an error while creating the staging DB.Check error.log for details.")
                err = utils.process_exit_codes(exit_code,"DBLINK",std_err)
                logger.error(err)
                raise err
        elif dSourceType == "Manual Backup Ingestion":
            logger.debug("dSourceType is Manual Backup Ingestion") 
            logger.debug("Inside linked_pre_snapshot() > resync () > dSourceType is Replication")
            environment_vars={
                "DLPX_LIBRARY_SOURCE" : library_script,
                "DLPX_BIN" : binary_path,
                "MYSQLD":repository.install_path,
                "MYSQLVER":repository.version,
                "SOURCEUSER":staged_source.parameters.source_user,
                "SOURCEPASS":staged_source.parameters.source_pass,
                "STAGINGSERVERID":staged_source.parameters.server_id,
                "STAGINGPORT":staged_source.parameters.staging_port,
                "STAGINGCONN":stagingConn,
                "STAGINGPASS":staged_source.parameters.staging_pass,
                "STAGINGDATADIR":mount_path,
                "SOURCEBASEDIR":source_config.base_dir,
                "STAGINGHOSTIP":staging_ip
            }  
            logger.debug("Initializing Seed DB")
            restore_script = pkgutil.get_data('resources', 'restore_stage_bi.sh')
            result = libs.run_bash(staged_source.staged_connection, restore_script,environment_vars,check=False)
            output = result.stdout.strip()
            std_err = result.stderr.strip()
            exit_code = result.exit_code
            if exit_code !=0:
                logger.debug("There was an error while creating the seed database. Check error logs for more info.")
                logger.error("Error is : "+std_err)
                err = utils.process_exit_codes(exit_code,"DBLINK",std_err)
                logger.error(err)
                raise err
            else:
                logger.debug("Pre-Snapshot/Restore_DB successful "+output)  
        else:
            # Simple Tablespace Option is hidden from the plugin.
            # This section will not get triggered until the option gets added back in schema.json
            logger.debug("dSourceType is Simple Tablespace Copy")
            environment_vars={
                "DLPX_LIBRARY_SOURCE" : library_script,
                "DLPX_BIN" : binary_path,
                "MYSQLD":repository.install_path,
                "MYSQLVER":repository.version,
                "SOURCEDATADIR":source_config.data_dir,
                "SOURCEBASEDIR":source_config.base_dir,
                "SOURCEPORT":source_config.port,
                "SOURCEIP":staged_source.parameters.sourceip,
                "SOURCECONN":sourceConn,
                "SOURCEUSER":staged_source.parameters.source_user,
                "SOURCEPASS":staged_source.parameters.source_pass,
                "SOURCEDATABASE":staged_source.parameters.source_database,
                "SOURCETABLES":staged_source.parameters.source_tables,
                "STAGINGSERVERID":staged_source.parameters.server_id,
                "STAGINGPORT":staged_source.parameters.staging_port,
                "STAGINGCONN":stagingConn,
                "STAGINGPASS":staged_source.parameters.staging_pass,
                "SCPUSER":staged_source.parameters.scp_user,
                "SCPPASS":staged_source.parameters.scp_pass,
                "STAGINGDATADIR":mount_path,
                "STAGINGHOSTIP":staging_ip,
                "STAGINGBASEDIR": staged_source.parameters.staging_basedir
            }      
            restore_script = pkgutil.get_data('resources', 'restore_stage_si.sh')
            result = libs.run_bash(staged_source.staged_connection, restore_script,environment_vars,check=True)
            output = result.stdout.strip()
            error = result.stderr.strip()
            exit_code = result.exit_code
            if exit_code !=0:
                logger.debug("There was an error while resync : "+error)
                raise LinkingException("Exception in pre-snapshot/restore_db:"+error)
            else:
                logger.debug("Pre-Snapshot/Restore_DB successful "+output)   

    # Simple Tablespace Option is hidden from the plugin.
    # This section will not get triggered until the option gets added back in schema.json
    # if dSourceType == "Simple (Tablespace Backup)":
    #     library_script=pkgutil.get_data('resources','library.sh')
    #     binary_path=staged_source.staged_connection.environment.host.binary_path
    #     mount_path=staged_source.parameters.mount_path
    #     # Buiding Connection Strings for Hybrid Code
    #     sourceConn=build_lua_connect_string(staged_source.parameters.source_user,staged_source.parameters.sourceip)
    #     stagingConn=build_lua_connect_string(staged_source.parameters.staging_user, staging_ip)
    #     logger.debug("PreSnapshot for Simple Tablespace Copy")
    #     environment_vars={
    #         "DLPX_LIBRARY_SOURCE" : library_script,
    #         "DLPX_BIN" : binary_path,
    #         "MYSQLD":repository.install_path,
    #         "MYSQLVER":repository.version,
    #         "SOURCEDATADIR":source_config.data_dir,
    #         "SOURCEBASEDIR":source_config.base_dir,
    #         "SOURCEPORT":source_config.port,
    #         "SOURCEIP":staged_source.parameters.sourceip,
    #         "SOURCECONN":sourceConn,
    #         "SOURCEUSER":staged_source.parameters.source_user,
    #         "SOURCEPASS":staged_source.parameters.source_pass,
    #         "SOURCEDATABASE":staged_source.parameters.source_database,
    #         "SOURCETABLES":staged_source.parameters.source_tables,
    #         "STAGINGSERVERID":staged_source.parameters.server_id,
    #         "STAGINGPORT":staged_source.parameters.staging_port,
    #         "STAGINGCONN":stagingConn,
    #         "STAGINGPASS":staged_source.parameters.staging_pass,
    #         "SCPUSER":staged_source.parameters.scp_user,
    #         "SCPPASS":staged_source.parameters.scp_pass,
    #         "STAGINGDATADIR":mount_path,
    #         "STAGINGHOSTIP":staging_ip,
    #         "STAGINGBASEDIR": staged_source.parameters.staging_basedir
    #     }
    #     tbsp_script = pkgutil.get_data('resources', 'tablespaces.sh')
    #     result = libs.run_bash(staged_source.staged_connection, tbsp_script,environment_vars,check=True)
    #     output = result.stdout.strip()
    #     error = result.stderr.strip()
    #     exit_code = result.exit_code
    #     if exit_code !=0:
    #         logger.debug("There was an error while copying tablespace : "+error)
    #         raise LinkingException("Exception in pre-snapshot/tablespace copy:"+error)
    #     else:
    #         logger.debug("Pre-Snapshot/Restore_DB successful "+output)
    # Stopping DB prior to snapshot
    stop_staging(staged_source,repository,source_config)
    logger.debug(" linked_pre_snapshot > End ")

##################################################
# Function perform post-snapshot tasks
# Format: Python
##################################################

def linked_post_snapshot(
        staged_source,
        repository,
        source_config,
        snapshot_parameters
):
    logger.debug("plugin_opertions.linked_post_snapshot - Start ") 
    dSourceType = staged_source.parameters.d_source_type
    start_staging(staged_source,repository,source_config)
    logger.debug(snapshot_parameters)
    mount_path=staged_source.parameters.mount_path
    snapshot = SnapshotDefinition(validate=False)
    snapshot.snapshot_id= str(utils.get_snapshot_id())
    snapshot.snap_host=staged_source.staged_connection.environment.host.name
    snapshot.snap_port=staged_source.parameters.staging_port
    snapshot.snap_data_dir=mount_path+"/data"
    snapshot.snap_base_dir=source_config.base_dir
    snapshot.snap_pass=staged_source.parameters.staging_pass
    snapshot.snap_backup_path=staged_source.parameters.backup_path
    snapshot.snap_time=utils.get_current_time()
    logger.debug(snapshot)
    logger.debug("linked_post_snapshot - End ")                   
    return snapshot

##################################################
# Function to check status of Staging DB
# Format: Hybrid ( Python calls Shell Script )
##################################################

def linked_status(staged_source, repository, source_config):
    logger.debug("Checking status of Staging DB")
    library_script=pkgutil.get_data('resources','library.sh')
    binary_path=staged_source.staged_connection.environment.host.binary_path
    logger.debug(" Staging Port >>: "+staged_source.parameters.staging_port)
    environment_vars={
        "DLPX_LIBRARY_SOURCE" : library_script,
        "STAGINGPORT":staged_source.parameters.staging_port,
        "DLPX_BIN" : binary_path
    }
    status_script = pkgutil.get_data('resources', 'statusStaged.sh')
    result = libs.run_bash(staged_source.staged_connection, status_script,environment_vars,check=True)
    output = result.stdout.strip()
    error = result.stderr.strip()
    exit_code = result.exit_code 
    if exit_code !=0:
        logger.debug("Exception while checking Staging DB Status : "+error)
        #ignore status?
    else:
        logger.debug("Staging Status Check: "+output)  
    if output == "ACTIVE":
        return Status.ACTIVE
    else:
        return Status.INACTIVE
        
##################################################
# Function to Configure VDB
# Format: Hybrid ( Python calls Shell Script )
##################################################

def configure(virtual_source, snapshot, repository):
    logger.debug("virtual.configure")
    binary_path=virtual_source.connection.environment.host.binary_path
    library_script=pkgutil.get_data('resources','library.sh')
    mount_path=virtual_source.mounts[0].mount_path
    vdbConn=build_lua_connect_string(
                virtual_source.parameters.vdb_user,
                "localhost"
    )
    logger.debug("Mount Path:"+mount_path)
    logger.debug("Snapshot Settings:")
    logger.debug(snapshot)
    logger.debug("Snapshot_id"+snapshot.snapshot_id)
    logger.debug("Config Settings: ")
    config_settings_prov = virtual_source.parameters.config_settings_prov
    logger.debug(config_settings_prov)
    config_params=""
    ###################################################################
    # TODO: Operation fails if there are config settings. Must revisit.
    ###################################################################
    if len(config_settings_prov) > 0:
        for config_setting in config_settings_prov:
            logger.debug("PropertyName")
            logger.debug(config_setting['propertyName'])
            logger.debug("Value")
            logger.debug(config_setting['value'])
            config_params+=config_setting['propertyName']
            config_params+="="
            config_params+=config_setting['value']
            config_params+="\n"
            logger.debug("config_params:"+config_params)
    logger.debug("config_params:"+config_params)
    ###################################################################

    environment_vars={
        "DLPX_LIBRARY_SOURCE" : library_script,
        "DLPX_DATA_DIRECTORY":mount_path,   
        "DLPX_BIN" : binary_path,  
        "MYSQLD":repository.install_path,
        "MYSQLVER":repository.version,
        "VDBCONN":vdbConn,
        "VDBPASS":virtual_source.parameters.vdb_pass,
        "MYBASEDIR":virtual_source.parameters.base_dir,
        "PORT":virtual_source.parameters.port,
        "SERVERID":virtual_source.parameters.server_id,
        "MYCONFIG":config_params,
        #"STAGED_HOST":snapshot.snap_host,
        "STAGED_PORT":snapshot.snap_port,
        "STAGED_DATADIR":snapshot.snap_data_dir,
        "CONFIG_BASEDIR":snapshot.snap_base_dir,
        "STAGED_ROOT_PASS":snapshot.snap_pass,
        "STAGED_BACKUP":snapshot.snap_backup_path
    }
    configure_script = pkgutil.get_data('resources', 'provision.sh')
    result = libs.run_bash(virtual_source.connection, configure_script,environment_vars,check=False)
    logger.debug(result)
    output = result.stdout.strip()
    std_err=result.stderr.strip()
    exit_code = result.exit_code
    if exit_code == 0:
        logger.debug("Pre-Snapshot/Restore_DB successful "+output)
    else:
        err = utils.process_exit_codes(exit_code,"PROVISION",std_err)
        logger.debug("There was an error while provisioning.Check error.log for details.")
        logger.error(err)
        raise err
    return SourceConfigDefinition(
        db_name=output,
        base_dir=virtual_source.parameters.base_dir,
        port=virtual_source.parameters.port,
        data_dir=mount_path
    )


##################################################
# Function to stop a MySQL DB
# Format: Python
##################################################
def stop_mysql(port,connection,baseDir,user,pwd,host):
    #This function will stop a running MySQL Database.
    logger.debug("Commence > stop_mysql()")
    port_stat=get_port_status(port,connection)
    logger.debug("Port Status > "+port_stat.name)
    vdbConn=build_lua_connect_string(user,host)
    environment_vars={
    }
    if(port_stat == Status.ACTIVE):
        logger.debug("DB is Running. Shutting down.")
        shutdown_cmd = "%s/bin/mysqladmin %s'%s' --protocol=TCP --port=%s shutdown" % (baseDir,vdbConn,pwd,port)
        logger.debug("Shutdown Command: {}".format(shutdown_cmd))
        result = libs.run_bash(connection, shutdown_cmd,environment_vars,check=True)
        output = result.stdout.strip()
        error = result.stderr.strip()
        exit_code = result.exit_code
        if exit_code !=0:
            logger.debug("There was an error trying to shutdown the database : "+error)
            #raise MySQLShutdownException(error)
        else:
            logger.debug("Output: "+output)
        time.sleep(20)
        if(Status.ACTIVE == get_port_status(port,connection)):
            logger.debug("MySQL has not shutdown after 20 seconds. Killing process.")
            kill_process(connection,port)
    else:
        logger.debug(" MySQL database is already shutdown.")

##################################################
# Function to Kill a Process
# Format: Python
##################################################
def kill_process(connection,port):
    logger.debug("Killing Process running on port {}".format(port))
    process_cmd=CommandFactory.get_process_id(port)
    try:
        _bashresult = runbash(connection,process_cmd,None)
        _output=_bashresult.stdout.strip()
        _bashErrMsg=_bashresult.stderr.strip()
        _bashErrCode=_bashresult.exit_code
        if _bashErrCode!=0:
            raise Exception(_bashErrMsg)
        else:
            trimmedOut= re.sub("\s\s+", " ", _output)
            process_id= trimmedOut.split(" ")[1]
            if _output!="" and _output !=None and process_id!="":
                _bashresult = runbash(connection,CommandFactory.kill_process,None)
                _bashErrCode=_bashresult.exit_code
                if _bashErrMsg!=0:
                    logger.debug("Unable to kill the process")
                    raise Exception(_bashresult.stderr.strip())
    except Exception as err:
        logger.debug("There was an error while trying to kill the MySQL Process at {}".format(port))
        raise err

###################################################################
# Function to get the current status MySQL instance given the port#
# Format: Python
###################################################################

def get_port_status(port,connection):
    myport = port
    status = Status.INACTIVE
    output=""
    try:
        port_status_cmd="ps -ef | grep -E \"[m]ysqld .*--port="+myport+"\" | grep -v grep"
        result = libs.run_bash(connection, port_status_cmd,variables=None,check=True)
        output = result.stdout.strip()
    except Exception as err:
        logger.debug("Port Check Failed.: "+err.message)
    if output== "": 
        port_status_cmd="ps -ef | grep -E \"[m]ysqld .*-p.*"+myport+" | grep -v grep"
        try:
            result = libs.run_bash(connection, port_status_cmd,variables=None,check=True)
            output = result.stdout.strip() 
        except Exception as err:
            logger.debug("Port Check Failed for second cmd: "+err.message)      
    logger.debug("Port Status Response >")
    logger.debug(output)

    if output== "":
        logger.debug("MySQL DB is NOT RUNNING at Port:"+myport)
    else:
        logger.debug("A process is running at Port.")
        output = re.sub("\s\s+", " ", output)
        process_data = output.split(" ")
        process_id = process_data[1]
        bin_dir = process_data[7]
        data_dir=""
        data_dir_attr = process_data[10]
        data_dir_list = data_dir_attr.split("=")
        logger.debug("process_id: "+process_id+" bin_dir: "+bin_dir+" data_dir_attr: "+data_dir_attr)
        if len(data_dir_list)>1:
            logger.debug("data_dir_list length is greater than 1")
            data_dir=data_dir_list[1]
            logger.debug("data_dir: "+data_dir)
        if (process_id !="" and bin_dir !="" and data_dir != ""):
            logger.debug("MySQL DB is running at PORT %s with PROCESS ID: %s" %(myport,process_id))
            status = Status.ACTIVE
    return status

##################################################
# Function to start MySQL DB
# Format: Python
##################################################
def start_mysql(installPath,baseDir,mountPath,port,serverId,connection):
    #This function will stop a running MySQL Database.
    logger.debug("Commence > start_mysql()")
    port_stat=get_port_status(port,connection)
    logger.debug("Port Status > "+port_stat.name)
    environment_vars={
    }
    if(port_stat == Status.INACTIVE):
        logger.debug("DB is not running. Starting the MySQL DB")
        start_cmd=get_start_cmd(installPath,baseDir,mountPath,port,serverId)
        logger.debug("Startup Command: {}".format(start_cmd))
        result = libs.run_bash(connection, start_cmd,environment_vars,check=True)
        output = result.stdout.strip()
        error = result.stderr.strip()
        exit_code = result.exit_code
        if exit_code !=0:
            logger.debug("There was an error trying to start the DB : "+error)
            raise UserError(
                constants.ERR_START_MSG,
                constants.ERR_START_ACTION,
                "ExitCode:{} \n {}".format(exit_code,error)
            )
        else:
            logger.debug("Output: "+output)
        time.sleep(30)
        if(Status.ACTIVE == get_port_status(port,connection)):
            logger.debug("DB Started Successfully")
        else:
            logger.debug("There was an issue starting the DB")
    else:
        logger.debug(" DB is already Running.")


##################################################
# Function to start MySQL DB Slave Replication
# Format: Python
##################################################
def start_slave(connection,installPath,port,connString,username,pwd,hostIp):
    start_slave_cmd=""
    environment_vars={
    }
    if (installPath=="" or port=="" or (connString=="" and username=="") or pwd=="" or hostIp==""):
        logger.debug("One of the required parameters are empty. Cannot continue.")
        raise Exception("One of the required params for MySQL Connection is empty")
    else:
        start_slave_cmd=CommandFactory.start_replication(connection,installPath,port,connString,username,pwd,hostIp)
        logger.debug("Connection String with {}".format(start_slave_cmd))     
        try:
            logger.debug("Starting Slave")
            result = libs.run_bash(connection, start_slave_cmd,environment_vars,check=True)
            output = result.stdout.strip()
            logger.debug("Start Slave Output: {}".format(output))
        except Exception as err:
            logger.debug("Starting Slave Failed: "+err.message)
            raise err

##################################################
# Function to stop MySQL DB Slave Replication
# Format: Python
##################################################
def stop_slave(connection,installPath,port,connString,username,pwd,hostIp):
    stop_slave_cmd=""
    environment_vars={
    }
    if (installPath=="" or port=="" or (connString=="" and username=="") or pwd=="" or hostIp==""):
        logger.debug("One of the required parameters are empty. Cannot continue.")
        raise Exception("One of the required params for MySQL Connection is empty")
    else:
        stop_slave_cmd=CommandFactory.stop_replication(connection,installPath,port,connString,username,pwd,hostIp)
        logger.debug("Connection String with {}".format(stop_slave_cmd))    
        try:
            logger.debug("Stopping Replication")
            result = libs.run_bash(connection, stop_slave_cmd,environment_vars,check=True)
            _output=result.stdout.strip()
            _bashErrMsg=result.stderr.strip()
            _bashErrCode=result.exit_code
            if _bashErrCode!=0:
                logger.debug("Stopping Slave was not succesful")
                raise Exception(_bashErrMsg)
            logger.debug("Start Slave Response: {}".format(_output))
        except Exception as err:
            logger.debug("Stop Replication Failed Due To: "+err.message)       
            logger.debug("Ignoring and continuing")

##################################################
# Function to build LUA code connection string
# Format: Python
##################################################
def build_lua_connect_string(user,host):
    return CommandFactory.build_lua_connect_string(user,host)       

def get_connection_cmd(installPath,port,connString,username,pwd,hostIp):
    connection_cmd=""
    if (port=="" or (connString=="" and username=="") or pwd=="" or hostIp==""):
        logger.debug("One of the required parameters are empty. Cannot continue.")
        raise ValueError("One of the required params for MySQL Connection is empty")
    else:
        connection_cmd=CommandFactory.connect_to_mysql(installPath,port,connString,username,pwd,hostIp)
        logger.debug("connaction_cmd >"+connection_cmd) 
    return connection_cmd

##################################################
# Function to get the MySQL DB Start Command
# Format: Python
##################################################
def get_start_cmd(installPath,baseDir,mountPath,port,serverId):
    startup_cmd=""
    if (mountPath=="" or port=="" or serverId=="" or installPath==""):
        logger.debug("One of the required parameters are empty. Cannot continue.")
        raise ValueError("One of the required params for MySQL Connection is empty")
    else:
        startup_cmd=CommandFactory.start_mysql(installPath,baseDir,mountPath,port,serverId)
    return startup_cmd

##################################################
# Function to run bash command on target
# Format: Python
##################################################
def runbash(connection, command,environmentVars):
    logger.debug("operatins.runbash() >>")
    return libs.run_bash(connection, command,variables=environmentVars,check=True)


########################################################
# DO NOT USE
########################################################
def repository_discovery(source_connection):
    # This is an object generated from the repositoryDefinition schema.
    # In order to use it locally you must run the 'build -g' command provided
    # by the SDK tools from the plugin's root directory.
    repositories = []
    binary_path=source_connection.environment.host.binary_path
    library_script=pkgutil.get_data('resources','library.sh')
    environment_vars={
        "DLPX_LIBRARY_SOURCE" : library_script,
        "DLPX_BIN" : binary_path
    }
    find_mysql_binary = pkgutil.get_data('resources', 'repoDiscovery.sh')
    result = libs.run_bash(source_connection, find_mysql_binary,environment_vars,check=True)
    output = result.stdout.strip()
    error = result.stderr.strip()
    exit_code = result.exit_code
    if exit_code !=0:
        logger.debug("Error is : "+error)
        raise RepositoryDiscoveryError("Exception while discovering:"+error)
    else:
        logger.debug("Output: "+output)
        #process repository json
        repos_js=json.loads(output)
        # print the keys and values
        for repo_js in repos_js:
            #logger.debug("Adding repository:"+repo_js+" to list")
            path = repo_js['installPath']
            version = repo_js['version']
            prettyName = repo_js['prettyName'].split("/bin")[1]
            repository = RepositoryDefinition(name=prettyName, install_path=path, version=version)
            repositories.append(repository)
    logger.debug("output:"+output)
    return repositories
