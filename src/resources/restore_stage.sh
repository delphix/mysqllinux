#!/bin/sh
# Copyright (c) 2018 by Delphix. All rights reserved.
PGM_NAME='restore_stage.sh'

# Load Library ...
eval "${DLPX_LIBRARY_SOURCE}"
result=`library_load`
log "Start ${PGM_NAME}"
log "Library Load Status: $result"

who=`whoami`
log "whoami: $who"
pw=`pwd`
log "pwd: $pw"

AWK=`which awk`
log "awk: ${AWK}"

DT=`date '+%Y%m%d%H%M%S'`

# Software Binaries
INSTALL_BIN="${SOURCEBASEDIR}/bin"
log "Binaries: ${INSTALL_BIN}"

# Ports
SOURCE_PORT=${SOURCEPORT}
TARGET_PORT=${STAGINGPORT}
log "Source Port: ${SOURCE_PORT}"
log "Staging Port: ${TARGET_PORT}"

# Replication Variables ...
log "========= Replication Variables ==========="
log "Staging Host: ${STAGINGHOSTIP}"
MASTER_HOST="${SOURCEIP}"
log "Master Host: ${SOURCEIP}"
MASTER_USER="${REPLICATION_USER}"
log "REPLICATION_USER: ${REPLICATION_USER}"
MASTER_PORT="${SOURCEPORT}"
log "MASTER_PORT: ${MASTER_PORT}"
MASTER_PASS="${REPLICATION_PASS}"

# Directory Paths ...
NEW_MOUNT_DIR="${STAGINGDATADIR}"
log "Staging Base Directory: ${NEW_MOUNT_DIR}"

NEW_DATA_DIR="${NEW_MOUNT_DIR}/data"
NEW_LOG_DIR="${NEW_MOUNT_DIR}/log"
NEW_TMP_DIR="${NEW_MOUNT_DIR}/tmp"
NEW_MY_CNF="${NEW_MOUNT_DIR}/my.cnf"
NEW_SERVER_ID="${STAGINGSERVERID}"

########## Sanity Checks###############
# 1. Data Directory must be empty
#######################################
if [ ! -z "$(ls -A ${NEW_DATA_DIR})" ]; then
   log " Data directory is not empty. This is a resync of an existing database."
   cleanup_dir NEW_DATA_DIR
   cleanup_dir NEW_LOG_DIR
   cleanup_dir NEW_TMP_DIR
   log " Cleanup complete."
fi

# Backup File Location
if [[ "${BACKUP_PATH}" == "" ]]; then
   BKUP_FILE="/tmp/dump_${SOURCE_PORT}.sql"
else 
   BKUP_FILE="${BACKUP_PATH}"
fi 
log "Backup File: ${BKUP_FILE}"



# Staging Connection for Install/Configuration
STAGINGPASS=`echo "'"${STAGINGPASS}"'"`

masklog "Staging Connection: ${STAGINGCONN}"
RESULTS=$( buildConnectionString "${STAGINGCONN}" "${STAGINGPASS}" "${STAGINGPORT}" "${STAGINGHOSTIP}" )
echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".string"
STAGING_CONN=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".string"`
masklog "Staging Connection: ${STAGING_CONN}"

###########################################################
## On Staging Server ...
# scp from source server the ${BKUP_FILE}
# Get master log file and position ...
#
log "LogSync Enabled: ${LOGSYNC}"
if [[ "${LOGSYNC}" == "true" ]]
then
   #head ${BKUP_FILE} -n80 | grep "MASTER_LOG_POS"
   STR=$( head ${BKUP_FILE} -n80 | grep "MASTER_LOG_POS" )
   BINLOG_FILENAME=`echo "${STR}" | ${AWK} -F"=" '{print $2}' | cut -d"," -f1 | tr -d \'`
   BINLOG_POSITION=`echo "${STR}" | ${AWK} -F"=" '{print $3}' | cut -d";" -f1`
   log "BackupFile: ${BKUP_FILE}"
   log "MasterLogFile: ${BINLOG_FILENAME}"
   log "MasterLogPosition: ${BINLOG_POSITION}"
fi 

# Create Initial Database ...
log "MySQL Version: ${MYSQLVER}"
log "Source --basedir=${SOURCEBASEDIR}"
log "Source --datadir=${SOURCEDATADIR}"
log "Creating Initial Database"

# Create Initial Database 5.7 or later ...
log "Using mysqld --initialize"

log "${MYSQLD}/mysqld --initialize --user=mysql --datadir=${NEW_DATA_DIR} --log-error=${NEW_DATA_DIR}/mysqld.log"
${MYSQLD}/mysqld --initialize --user=mysql --datadir=${NEW_DATA_DIR} --log-error=${NEW_DATA_DIR}/mysqld.log 1>>${DEBUG_LOG} 2>&1

PWD_LINE=`cat ${NEW_DATA_DIR}/mysqld.log | grep 'temporary password'`
# sudo grep 'temporary password' ${NEW_DATA_DIR}/mysqld.log`
# 2019-04-11T14:40:34.032576Z 1 [Note] A temporary password is generated for root@localhost: L0qXNZ8?C3Us
log "init temporary password: ${PWD_LINE}"

TMP_PWD=`echo "${PWD_LINE}" | ${AWK} -F": " '{print $2}' | xargs`
# These temporary passwords contain special characters so need to wrap in single / literal quotes ...
TMP_PWD=`echo "'"$TMP_PWD"'"`
log "Temporary Password: ${TMP_PWD}"
masklog "Staging Connection: ${STAGINGCONN}"
RESULTS=$( buildConnectionString "${STAGINGCONN}" "${TMP_PWD}" "${STAGINGPORT}" "${STAGINGHOSTIP}" )
echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".string"
STAGING_CONN=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".string"`
masklog "Staging Connection: ${STAGING_CONN}"
log "Creation Results: ${RESULTS}"

############################################################
log "Creating Staging Directories on NFS Mounted Path from Delphix"
mkdir -p ${NEW_DATA_DIR}
mkdir -p ${NEW_LOG_DIR}
mkdir -p ${NEW_TMP_DIR}

# This snippet creates a config file if one has not been provided.
log "my.cnf file location >  ${NEW_MY_CNF}"

if [[ -f "${DLPX_TOOLKIT}/my.cnf" ]]
then
   log "Copying Config File from ${DLPX_TOOLKIT}/my.cnf to ${NEW_MOUNT_DIR}"
   cp ${DLPX_TOOLKIT}/my.cnf ${NEW_MOUNT_DIR}
else
   log "Note: Customer can create own Replication Configuration file ${DLPX_TOOLKIT}/my.cnf"
   log "Since the above file was missing, Creating my.cnf file ..."
   echo "[mysql]" > ${NEW_MY_CNF}
   echo "server-id               = ${NEW_SERVER_ID}" >> ${NEW_MY_CNF}
   echo "binlog-format           = mixed" >> ${NEW_MY_CNF}
   echo "log_bin                 = ${NEW_LOG_DIR}/mysql-bin" >> ${NEW_MY_CNF}
   echo "relay-log               = ${NEW_LOG_DIR}/mysql-relay-bin" >> ${NEW_MY_CNF}
   echo "log-slave-updates       = 1" >> ${NEW_MY_CNF}
   echo "read-only               = 1" >> ${NEW_MY_CNF}
   echo "" >> ${NEW_MY_CNF}
   echo "basedir=${SOURCEBASEDIR}" >> ${NEW_MY_CNF}
   echo "datadir=${NEW_DATA_DIR}" >> ${NEW_MY_CNF}
   echo "tmpdir=${NEW_TMP_DIR}" >> ${NEW_MY_CNF}
   echo "socket=${NEW_MOUNT_DIR}/mysql.sock" >> ${NEW_MY_CNF}
   echo "port=${TARGET_PORT}" >> ${NEW_MY_CNF}
   ###echo "sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES" >> ${NEW_MY_CNF}
   echo "log-error=${NEW_MOUNT_DIR}/mysqld_error.log" >> ${NEW_MY_CNF}
   echo "" >> ${NEW_MY_CNF}
   echo "[mysqld_safe]" >> ${NEW_MY_CNF}
   echo "log-error=${NEW_MOUNT_DIR}/mysqld_error.log" >> ${NEW_MY_CNF}
   echo "pid-file=${NEW_MOUNT_DIR}/mysqld.pid" >> ${NEW_MY_CNF}
   echo "" >> ${NEW_MY_CNF}
fi

CMD=`ls -ll "${NEW_MY_CNF}"`
log "my.cnf exists?  ${CMD}"

if [[ -f "${NEW_MY_CNF}" ]]
then
   echo "Replace all tabs with spaces"
   sed -i 's/\t/     /g' ${NEW_MY_CNF}

   echo "Parameter port = $TARGET_PORT"
   CHK=`cat ${NEW_MY_CNF} | grep "^port"`
   if [[ "${CHK}" != "" ]]
   then
         sed -i "/^port/s;port;##dlpx##port;" ${NEW_MY_CNF}
         sed -i "/^##dlpx##port/s;##dlpx##port;port=${TARGET_PORT} ##dlpx##;" ${NEW_MY_CNF}
   else
         echo "port=${TARGET_PORT}" >> ${NEW_MY_CNF}
   fi
   echo "Port updated"

   echo "Parameter server-id = ${NEW_SERVER_ID}"
   CHK=`cat ${NEW_MY_CNF} | grep "^server-id"`
   if [[ "${CHK}" != "" ]]
   then
 		   sed -i "/^server-id/s;server-id;##dlpx##server-id;" ${NEW_MY_CNF}
         sed -i "/^##dlpx##server-id/s;##dlpx##server-id;server-id=${NEW_SERVER_ID} ##dlpx##;" ${NEW_MY_CNF}
   else
         echo "server-id=${NEW_SERVER_ID}" >> ${NEW_MY_CNF}
   fi
   echo "Server-Id updated"

   echo "Parameter binlog-format = mixed"
   CHK=`cat ${NEW_MY_CNF} | grep "^binlog-format"`
   if [[ "${CHK}" != "" ]]
   then
 		   sed -i "/^binlog-format/s;binlog-format;##dlpx##binlog-format;" ${NEW_MY_CNF}
         sed -i "/^##dlpx##binlog-format/s;##dlpx##binlog-format;binlog-format=mixed ##dlpx##;" ${NEW_MY_CNF}
   else
         echo "binlog-format=mixed" >> ${NEW_MY_CNF}
   fi
   echo "Bin-Log-Format updated"

   echo "Parameter log_bin"
   CHK=`cat ${NEW_MY_CNF} | grep "^log_bin"`
   if [[ "${CHK}" != "" ]]
   then
      	sed -i "/^log_bin/s;log_bin;##dlpx##log_bin;" ${NEW_MY_CNF}
      	sed -i "/^##dlpx##log_bin/s;##dlpx##log_bin;log_bin=${NEW_LOG_DIR}/mysql-bin ##dlpx##;" ${NEW_MY_CNF}
   else
      	echo "log_bin=${NEW_LOG_DIR}/mysql-bin" >> ${NEW_MY_CNF}
   fi
   echo "Log-Bin updated"

   echo "Parameter relay-log = ${NEW_LOG_DIR}/mysql-relay-bin"
   CHK=`cat ${NEW_MY_CNF} | grep "^relay-log"`
   if [[ "${CHK}" != "" ]]
   then
   		sed -i "/^relay-log/s;relay-log;##dlpx##relay-log;" ${NEW_MY_CNF}

       	sed -i "/^##dlpx##relay-log/s;##dlpx##relay-log;relay-log=${NEW_LOG_DIR}/mysql-relay-bin ##dlpx##;" ${NEW_MY_CNF}
   else
      	echo "relay-log=${NEW_LOG_DIR}/mysql-relay-bin" >> ${NEW_MY_CNF}
   fi
   echo "Relay-Log updated"

   echo "Parameter log-slave-update = 1"
   CHK=`cat ${NEW_MY_CNF} | grep "^log-slave-updates"`
   if [[ "${CHK}" != "" ]]
   then
   		sed -i "/^log-slave-updates/s;log-slave-updates;##dlpx##log-slave-updates;" ${NEW_MY_CNF}

       	sed -i "/^##dlpx##log-slave-updates/s;##dlpx##log-slave-updates;log-slave-updates=1 ##dlpx##;" ${NEW_MY_CNF}
   else
      	echo "log-slave-updates=1" >> ${NEW_MY_CNF}
   fi
   echo "Log-slave-update updated"

   echo "Parameter read-only = 1"
   CHK=`cat ${NEW_MY_CNF} | grep "^read-only"`
   if [[ "${CHK}" != "" ]]
   then
   		sed -i "/^read-only/s;read-only;##dlpx##read-only;" ${NEW_MY_CNF}
       	sed -i "/^##dlpx##read-only/s;##dlpx##read-only;read-only=1 ##dlpx##;" ${NEW_MY_CNF}
   else
      echo "read-only=1" >> ${NEW_MY_CNF}
   fi
   echo "Read-Only updated"

   echo "Parameter basedir = ${SOURCEBASEDIR}"
   CHK=`cat ${NEW_MY_CNF} | grep "^basedir"`
   if [[ "${CHK}" != "" ]]
   then
		sed -i "/^basedir/s;basedir;##dlpx##basedir;" ${NEW_MY_CNF}
		sed -i "/^##dlpx##basedir/s;##dlpx##basedir;basedir=${SOURCEBASEDIR} ##dlpx##;" ${NEW_MY_CNF}
   else
      echo "basedir=${SOURCEBASEDIR}" >> ${NEW_MY_CNF}
   fi
   echo "BaseDir updated"

   echo "Parameter datadir = ${NEW_DATA_DIR}"
   CHK=`cat ${NEW_MY_CNF} | grep "^datadir"`
   if [[ "${CHK}" != "" ]]
   then
		sed -i "/^datadir/s;datadir;##dlpx##datadir;" ${NEW_MY_CNF}
		sed -i "/^##dlpx##datadir/s;##dlpx##datadir;datadir=${NEW_DATA_DIR} ##dlpx##;" ${NEW_MY_CNF}
   else
      echo "datadir=${NEW_DATA_DIR}" >> ${NEW_MY_CNF}
   fi
   echo "DataDir updated "

   echo "Parameter tmpdir = ${NEW_TMP_DIR}"
   CHK=`cat ${NEW_MY_CNF} | grep "^tmpdir"`
   if [[ "${CHK}" != "" ]]
   then
		sed -i "/^tmpdir/s;tmpdir;##dlpx##tmpdir;" ${NEW_MY_CNF}
		sed -i "/^##dlpx##tmpdir/s;##dlpx##tmpdir;tmpdir=${NEW_TMP_DIR} ##dlpx##;" ${NEW_MY_CNF}
   else
      echo "tmpdir=${NEW_TMP_DIR}" >> ${NEW_MY_CNF}
   fi
   echo "TmpDir updated"

   echo "Parameter socket = ${NEW_MOUNT_DIR}/mysql.sock"
   CHK=`cat ${NEW_MY_CNF} | grep "^socket"`
   if [[ "${CHK}" != "" ]]
   then
		sed -i "/^socket/s;socket;##dlpx##socket;" ${NEW_MY_CNF}
		sed -i "/^##dlpx##socket/s;##dlpx##socket;socket=${NEW_MOUNT_DIR}/mysql.sock ##dlpx##;" ${NEW_MY_CNF}
   else
      echo "socket=${NEW_MOUNT_DIR}/mysql.sock" >> ${NEW_MY_CNF}
   fi
   echo "Socket file updated"

   echo "Parameter log-error = ${NEW_MOUNT_DIR}/mysqld_error.log"
   CHK=`cat ${NEW_MY_CNF} | grep "^log-error"`
   if [[ "${CHK}" != "" ]]
   then
		sed -i "/^log-error/s;log-error;##dlpx##log-error;" ${NEW_MY_CNF}
		sed -i "/^##dlpx##log-error/s;##dlpx##log-error;log-error=${NEW_MOUNT_DIR}/mysqld_error.log ##dlpx##;" ${NEW_MY_CNF}
   else
      echo "log-error=${NEW_MOUNT_DIR}/mysqld_error.log" >> ${NEW_MY_CNF}
   fi
   echo "LogError updated"

   echo "Parameter pid-file = ${NEW_MOUNT_DIR}/mysqld.pid"
   CHK=`cat ${NEW_MY_CNF} | grep "^pid-file"`
   if [[ "${CHK}" != "" ]]
   then
		sed -i "/^pid-file/s;pid-file;##dlpx##pid-file;" ${NEW_MY_CNF}
		sed -i "/^##dlpx##pid-file/s;##dlpx##pid-file;pid-file=${NEW_MOUNT_DIR}/mysql.pid ##dlpx##;" ${NEW_MY_CNF}
   else
      echo "pid-file=${NEW_MOUNT_DIR}/mysql.pid" >> ${NEW_MY_CNF}
   fi
   echo "PID-File Updated"

else
   terminate "ERROR:Missing Customer Config File ${NEW_MY_CNF}. Delphix was unable to create a config file. Check log messages under toolkit directory for possible errors." 4
fi

CMD=`ls -ll ${NEW_MOUNT_DIR}`
log "Mount Directory Contents: ${CMD}"

# Initial Startup
RESULTS=$( portStatus "${TARGET_PORT}" )
zSTATUS=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".status"`
JSON="{
  \"port\": \"${TARGET_PORT}\",
  \"processId\": \"\",
  \"processCmd\": \"${MYSQLD}\",
  \"socket\": \"${NEW_MOUNT_DIR}/mysql.sock\",
  \"baseDir\": \"${SOURCEBASEDIR}\",
  \"dataDir\": \"${NEW_DATA_DIR}\",
  \"myCnf\": \"${NEW_MY_CNF}\",
  \"serverId\": \"${NEW_SERVER_ID}\",
  \"pidFile\": \"${NEW_MOUNT_DIR}/clone.pid\",
  \"tmpDir\": \"${NEW_TMP_DIR}\",
  \"logSync\": \"\",
  \"status\": \"${zSTATUS}\"
}"

# Skip LOGSYNC on initial startup ...
#  \"logSync\": \"${LOGSYNC}\",

##log "JSON: ${JSON}"

## Initial startup just involves starting the DB and restoring the backup. 
## Slave Server is not started at this time.
if [[ "${zSTATUS}" != "ACTIVE" ]]
then
   log "Initial Database Startup. Passing NO for START SLAVE"
   startDatabase "${JSON}" "${STAGING_CONN}" " " "NO"
else
   log "Database is Already Started ..."
fi

#
# See if instance started ...
#
PSEF=$( ps -ef | grep -E "[m]ysqld.*--port=${TARGET_PORT}" )
log "Process Status: ${PSEF}"

PSID=`echo "${PSEF}" | ${AWK} -F" " '{print $2}' | xargs`
log "Process Id: ${PSID}"

#
# If not started, die ...
#
if [[ "${PSID}" == "" ]] 
then
    log "MySQL Database could not be started."
    terminate "MySQL Database could not be started.No process running." 3
fi

# Setting up symbolic link to mysql.sock # NEO
#SOCKLN="${NEW_MOUNT_DIR}/mysql.sock"
#REMOVE=`rm /tmp/mysql.sock`   # ignore errors
#SOCK_SYM_LINK=`ln -s $SOCKLN /tmp/mysql.sock`

########################################################################
#
# Change Password for Staging Conn ...
#
#CMD="${INSTALL_BIN}/mysql ${STAGING_CONN} --connect-expired-password -se \"ALTER USER 'root'@'localhost' IDENTIFIED BY ${STAGINGPASS};UPDATE mysql.user SET authentication_string=PASSWORD(${STAGINGPASS}) where USER='root';FLUSH PRIVILEGES;\""
#CMDFORLOG="${INSTALL_BIN}/mysql ${STAGING_CONN} --connect-expired-password -se \"ALTER USER 'root'@'localhost' IDENTIFIED BY '********';UPDATE mysql.user SET authentication_string=PASSWORD('********') where USER='root';FLUSH PRIVILEGES;\""

CMD="${INSTALL_BIN}/mysql ${STAGING_CONN} --connect-expired-password -se \"ALTER USER 'root'@'localhost' IDENTIFIED BY ${STAGINGPASS};FLUSH PRIVILEGES;\""
CMDFORLOG="${INSTALL_BIN}/mysql ${STAGING_CONN} --connect-expired-password -se \"ALTER USER 'root'@'localhost' IDENTIFIED BY '********';FLUSH PRIVILEGES;\""
masklog "Final Command to Change Password is : ${CMDFORLOG}"
command_runner "${CMD}" 5

  #eval ${CMD} 1>>${DEBUG_LOG} 2>&1
  #return_msg=$(eval ${CMD} 2>&1 1>&2 > /dev/null)
  #return_code=$?
  #log "Return Status for change password: ${return_code}"
  #log "Return message for change password:${return_msg}"
  #if [ $return_code != 0 ]; then
  #  terminate "${return_msg}" 5
  #fi

# Update Staging Connection with supplied password ...
#
masklog "Staging Connection Prior to updaging password : ${STAGINGCONN}"
RESULTS=$( buildConnectionString "${STAGINGCONN}" "${STAGINGPASS}" "${STAGINGPORT}" "${STAGINGHOSTIP}" )
echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".string"
STAGING_CONN=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".string"`
masklog "Staging Connection after updating password: ${STAGING_CONN}"

########################################################################
# Load Source Database Export ...
CMD="${INSTALL_BIN}/mysql ${STAGING_CONN} -e \"RESET MASTER;\""
masklog "Reset Master Command:  ${CMD}"
eval ${CMD} 1>>${DEBUG_LOG} 2>&1

log "============================================================"
log "Restoring Backup File "
log "============================================================"
masklog "${INSTALL_BIN}/mysql ${STAGING_CONN} -f < ${BKUP_FILE}"
#RESULTS=$( ${INSTALL_BIN}/mysql ${STAGING_CONN} < ${BKUP_FILE} )
#log "Restore Results: ${RESULTS}"

## Reset Master before restoring backup
##RESET_MASTER="${DLPX_TOOLKIT}/reset_master.sql"
##echo "RESET MASTER;" > ${RESET_MASTER}

## Ingest Backup File
CMD="${INSTALL_BIN}/mysql ${STAGING_CONN} -f < ${BKUP_FILE}"
command_runner "${CMD}" 5
  #eval ${CMD} 1>>${DEBUG_LOG} 2>&1
  #return_msg=$(eval ${CMD} 2>&1 1>&2 > /dev/null)
  #return_code=$?
  #log "Return Status for ingest backup: ${return_code}"
  #log "Return message for ingest backup:${return_msg}"
  #if [ $return_code != 0 ]; then
  #  terminate "${return_msg}" 6
  #fi

log "Validating Restored Databases"
#RESULTS=`${INSTALL_BIN}/mysql ${STAGING_CONN} -e "show databases;"`
#log "show databases: ${RESULTS}"
CMD="${INSTALL_BIN}/mysql ${STAGING_CONN} -e \"show databases;\""
eval ${CMD} 1>>${DEBUG_LOG} 2>&1

#log "============================================================"
#log "Granting SUPER and SHUTDOWN"
#CMD="${INSTALL_BIN}/mysql ${STAGING_CONN} -e \"GRANT SELECT, SHUTDOWN, SUPER, RELOAD ,SHOW VIEW, EVENT, TRIGGER on *.* to '${SOURCEUSER}'@'localhost'; FLUSH PRIVILEGES;\""
#log ${CMD}
if [[ "${AWS_SOURCE}" == "true" ]]
log "AWS-RDS Privilege Elevation"
then
   # Privilege Elevation sql
   CMD="${INSTALL_BIN}/mysql ${STAGING_CONN} -se \"UPDATE mysql.user set Shutdown_priv='Y', Grant_priv='Y', Super_priv='Y' where mysql.user.User='${SOURCEUSER}' and mysql.user.Host='localhost';FLUSH PRIVILEGES;\""
   masklog "Privilege Elevation Command :${CMD}"
   # Running Privilege elevation
   command_runner "${CMD}" 13
fi

# Shutting down after the backup has been ingested.
log "============================================================"
log "Shutdown after restoring data ..."
log "============================================================"
RESULTS=$( portStatus "${TARGET_PORT}" )
##RESULTS=$($DLPX_BIN_JQ ".logSync = \"$LOGSYNC\"" <<< $RESULTS)
RESULTS=$($DLPX_BIN_JQ ".logSync = \"\"" <<< $RESULTS)
zSTATUS=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".status"`
if [[ "${zSTATUS}" == "ACTIVE" ]]
then
   log "Stopping Database ..."
   stopDatabase "${RESULTS}" "${STAGING_CONN}" ""
else
   log "Database is Already Shut Down ..."
fi

# Verify Database is Shutdown ...
PSEF=$( ps -ef | grep -E "[m]ysqld.*--port=${TARGET_PORT}" )
log "Process Status: ${PSEF}"

PSID=`echo "${PSEF}" | ${AWK} -F" " '{print $2}' | xargs`
log "Process Id: ${PSID}"

if [[ "${PSID}" != "" ]]
then
   die "ERROR: Database is not shutdown, please investigate ..."
fi

# Use Restored Database Password ...
if [[ "${SOURCEPASS}" != "" ]]
then
   STAGING_CONN="-u${SOURCEUSER} -p${SOURCEPASS} --protocol=TCP --port=${TARGET_PORT}"
else
   errorLog "Error: Source user password not found. Using root user."
   STAGING_CONN="-uroot --protocol=TCP --port=${TARGET_PORT}"
fi
log "============================================================"
masklog "New Connection String to Staging DB >> ${STAGING_CONN}"

#
# Start Database ...
#
log "Start STAGING after backup restore"
JSON="{
  \"port\": \"${TARGET_PORT}\",
  \"processId\": \"\",
  \"processCmd\": \"${MYSQLD}\",
  \"socket\": \"${NEW_MOUNT_DIR}/mysql.sock\",
  \"baseDir\": \"${SOURCEBASEDIR}\",
  \"dataDir\": \"${NEW_DATA_DIR}\",
  \"myCnf\": \"${NEW_MY_CNF}\",
  \"serverId\": \"${NEW_SERVER_ID}\",
  \"pidFile\": \"${NEW_MOUNT_DIR}/clone.pid\",
  \"tmpDir\": \"${NEW_TMP_DIR}\",
  \"logSync\": \"\",
  \"status\": \"\"
}"

startDatabase "${JSON}" "${STAGING_CONN}" "" ""

# Validate if Staging is started.
PSEF=$( ps -ef | grep -E "[m]ysqld.*--port=${TARGET_PORT}" )
log "Process Status: ${PSEF}"
PSID=`echo "${PSEF}" | ${AWK} -F" " '{print $2}' | xargs`
log "Process Id: ${PSID}"

if [[ "${PSID}" == "" ]]
then
   terminate "ERROR: Staging DB did not start after password change and backup ingestion.Cannot continue." 3
fi

log "Validating new connection string"
RESULTS=`${INSTALL_BIN}/mysql ${STAGING_CONN} -e "SELECT @@BASEDIR;"`
return_code=$?
log "Return Status for post ingestion startup: ${return_code}"
if [ $return_code != 0 ]; then
  terminate "Unable to connect to MySQL Staging DB after backup ingestion." 7
fi
log "Connection Test: ${RESULTS}"

# Setup SLAVE REPLICATION. 
# At this point, slave should have already started.

log "LogSync Enabled: ${LOGSYNC}"
if [[ "${LOGSYNC}" == "true" ]]
then
   # Setup Slave SQL
   TMPLOG="${DLPX_TOOLKIT}/tmp4"
   echo "STOP SLAVE;" > ${TMPLOG}.sql
   echo "RESET SLAVE;" > ${TMPLOG}.sql
   echo "CHANGE MASTER TO MASTER_HOST='${MASTER_HOST}'," >> ${TMPLOG}.sql
   echo "MASTER_PORT=${MASTER_PORT}," >> ${TMPLOG}.sql
   echo "MASTER_USER='${MASTER_USER}'," >> ${TMPLOG}.sql
   echo "MASTER_PASSWORD='${MASTER_PASS}'," >> ${TMPLOG}.sql
   echo "MASTER_LOG_FILE='${BINLOG_FILENAME}'," >> ${TMPLOG}.sql
   echo "MASTER_LOG_POS=${BINLOG_POSITION};" >> ${TMPLOG}.sql
   echo "START SLAVE;" >> ${TMPLOG}.sql
   echo "SHOW SLAVE STATUS\G" >> ${TMPLOG}.sql

   ##DEBUG##
   ##log "Staging Connection: ${STAGING_CONN}"
   ##TMP=`cat ${TMPLOG}.sql`
   ##log "Slave Master SQL: ${TMP}"
   ##log "${INSTALL_BIN}/mysql ${STAGING_CONN} -vvv < ${TMPLOG}.sql > ${TMPLOG}.out"

   # Start Slave
   log "Starting Slave"
   RESULTS=$(${INSTALL_BIN}/mysql ${STAGING_CONN} -vvv < ${TMPLOG}.sql)
   return_code=$?
   log "Return Status for starting slave: ${return_code}"
   if [ $return_code != 0 ]; then
     log "Unable to Start Slave. "
   fi
   RESULTS=`cat ${TMPLOG}.out | tr '\n' '|'`
   log "Starting Slave Results: ${RESULTS}"

   if [[ -f "${TMPLOG}.sql" ]] 
   then
      rm "${TMPLOG}.sql" 2>/dev/null
   fi
   if [[ -f "${TMPLOG}.out" ]] 
   then
      rm "${TMPLOG}.out" 2>/dev/null
   fi
   log "Checking Slave Status"
   masklog "${INSTALL_BIN}/mysql ${STAGING_CONN} -se \"SHOW SLAVE STATUS\G\""
   RESULTS=$(${INSTALL_BIN}/mysql ${STAGING_CONN} -se "SHOW SLAVE STATUS\G")
   log "Slave Status: ${RESULTS}"

   # A parting tip: Sometimes errors occur in replication. 
   # For example, if you accidentally change a row of data on your slave. 
   # If this happens, fix the data, then run:
   #STOP SLAVE;SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1;START SLAVE;
fi

 
# This section has been commented to enable Staging Target run 
# Anything with two ## are lines of code
# Last Shutdown otherwise the toolkit hangs here ...

##RESULTS=$( portStatus "${TARGET_PORT}" )
##zSTATUS=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".status"`

# Now LogSync should be started, so let's include this in our shutdown ...

##RESULTS=$($DLPX_BIN_JQ ".logSync = \"$LOGSYNC\"" <<< $RESULTS)

##if [[ "${zSTATUS}" == "ACTIVE" ]]
##then
##   log "Last Shutdown ..."
##   stopDatabase "${RESULTS}" "${STAGING_CONN}" ""
##else
##   log "Database is Already Shut Down ..."
##fi

log "Environment: "
export DLPX_LIBRARY_SOURCE=""
export REPLICATION_PASS=""
export STAGINGPASS=""
export SOURCEPASS=""
env | sort  >>$DEBUG_LOG
log " <<<End"
exit 0
