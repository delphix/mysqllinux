import logging
import random
import time
import pkgutil
import logging
import sys
import re
import os
from common import utils,constants
from common.commands import CommandFactory
from dlpx.virtualization import libs
from dlpx.virtualization.platform import Status
from customexceptions.plugin_exceptions import RepositoryDiscoveryError
from customexceptions.database_exceptions import (
    StagingStartupException,
    StagingShutdownException,
    ReplicationSetupException,
    SourceBackupException,
    MySQLShutdownException,
    MySQLStartupException
)
from generated.definitions import (
    RepositoryDefinition,
    SourceConfigDefinition,
    SnapshotDefinition
)

logger = logging.getLogger(__name__)

def stop_mysql(port,connection,baseDir,vdbConn,pwd):
    #This function will stop a running MySQL Database.
    logger.debug("Commence > stop_mysql()")
    port_stat=get_port_status(port,connection)
    logger.debug("Port Status > "+port_stat.name)
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
            raise MySQLShutdownException(error)
        else:
            logger.debug("Output: "+output)
        time.sleep(25)
        if(Status.ACTIVE == get_port_status(port,connection)):
            logger.debug("KILL")  
            # TODO: Kill Process
    else:
        logger.debug(" DB is already down.")


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


# Get the current status MySQL instance given the port#
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
            raise MySQLStartupException(error)
        else:
            logger.debug("Output: "+output)
        time.sleep(25)
        if(Status.ACTIVE == get_port_status(port,connection)):
            logger.debug("DB Started Successfully")
        else:
            logger.debug("There was an issue starting the DB")
    else:
        logger.debug(" DB is already Running.")

def get_start_cmd(installPath,baseDir,mountPath,port,serverId):
    startup_cmd=""
    if (mountPath=="" or port=="" or serverId=="" or installPath==""):
        logger.debug("One of the required parameters are empty. Cannot continue.")
        raise Exception("One of the required params for MySQL Connection is empty")
    else:
        startup_cmd= "%s/mysqld --defaults-file=%s/my.cnf --basedir=%s --datadir=%s/data \
            --pid-file=%s/clone.pid --port=%s --server-id=%s --socket=%s/mysql.sock \
                --tmpdir=%s/tmp </dev/null >/dev/null 2>&1 & disown \"$!\"" % (installPath,mountPath,baseDir,mountPath,mountPath,port,serverId,mountPath,mountPath)
    return startup_cmd

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

# Builds LUA Connect String
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

def get_start_cmd(installPath,baseDir,mountPath,port,serverId):
    startup_cmd=""
    if (mountPath=="" or port=="" or serverId=="" or installPath==""):
        logger.debug("One of the required parameters are empty. Cannot continue.")
        raise ValueError("One of the required params for MySQL Connection is empty")
    else:
        startup_cmd=CommandFactory.start_mysql(installPath,baseDir,mountPath,port,serverId)
    return startup_cmd

# RunBash on Target Host
def runbash(connection, command,environmentVars):
    logger.debug("operatins.runbash() >>")
    return libs.run_bash(connection, command,variables=environmentVars,check=True)

# Find Repository Information on Host
def find_mysql_binaries(connection):
    logger.debug("operations.find_mysql_binaries()")
    baseName=""
    version=""
    dirName=""
    prettyName=""
    try:
        _bashresult = runbash(connection,CommandFactory.find_binary_path(),None)
        _repoList=_bashresult.stdout.strip()
        _bashErrMsg=_bashresult.stderr.strip()
        _bashErrCode=_bashresult.exit_code
        logger.debug("find_mysql_binaries>_repoList > \n "+_repoList)
        repositories=[]
        if _bashErrCode !=0:
            logger.debug("find_mysql_binaries > exit code> "+str(_bashErrCode))
            raise RepositoryDiscoveryError(_bashErrMsg)
        elif (_repoList =="" or _repoList is None ):
            logger.debug("find_mysql_binaries > No MySQL repositories found")
        else:
            for repoPath in _repoList.splitlines():
                logger.debug("Parsing repository at "+repoPath)
                baseName=os.path.basename(repoPath)
                dirName=os.path.dirname(repoPath)
                _bashresult=runbash(connection,CommandFactory.get_version(repoPath),None)
                versionStr=_bashresult.stdout.strip()
                versionArr=versionStr.split(" ")
                version=versionArr[3]
                if (version !="" and baseName =="mysqld"):
                    prettyName= versionStr[versionStr.index("(MySQL"):len(versionStr)]
                    prettyName= prettyName+" {}".format(version)
                    repository = RepositoryDefinition(name=prettyName, install_path=dirName, version=version)
                    repositories.append(repository)
    except RepositoryDiscoveryError as err:
        raise RepositoryDiscoveryError(err.message).to_user_error(), None, sys.exc_info()[2]
    except Exception as err:
        raise
    return repositories
