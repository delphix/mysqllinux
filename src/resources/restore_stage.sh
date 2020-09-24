#!/bin/sh
#
# Copyright (c) 2018 by Delphix. All rights reserved.
#

##DEBUG## In Delphix debug.log
#set -x

#
# Program Name ...
#
PGM_NAME='restore_stage.sh'

#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
result=`hey`
log "------------------------- Start"
log "Library Loaded ... hey $result"

who=`whoami`
log "whoami: $who"
pw=`pwd`
log "pwd: $pw"

AWK=`which awk`
log "awk: ${AWK}"

DT=`date '+%Y%m%d%H%M%S'`

#
# Software Binaries ...
#
INSTALL_BIN="${SOURCEBASEDIR}/bin"
log "Binaries: ${INSTALL_BIN}"

#
# Ports ...
#
SOURCE_PORT=${SOURCEPORT}
TARGET_PORT=${STAGINGPORT}
log "Source Port: ${SOURCE_PORT}"
log "Staging Port: ${TARGET_PORT}"

#
# Backup File Location ...
#
if [[ "${BACKUP_PATH}" == "" ]]
then
   BKUP_FILE="/tmp/dump_${SOURCE_PORT}.sql"
else 
   BKUP_FILE="${BACKUP_PATH}"
fi 
log "Backup File: ${BKUP_FILE}"

#
# Staging Connection for Install/Configuration ...
#
STAGINGPASS=`echo "'"${STAGINGPASS}"'"`

log "Staging Connection: ${STAGINGCONN}"
RESULTS=$( buildConnectionString "${STAGINGCONN}" "${STAGINGPASS}" "${STAGINGPORT}" "${STAGINGHOSTIP}" )
echo "${RESULTS}" | jq --raw-output ".string"
STAGING_CONN=`echo "${RESULTS}" | jq --raw-output ".string"`
log "Staging Connection: ${STAGING_CONN}"

#
# Replication Variables ...
#
log "========= Replication Variables ==========="
log "Staging Host: ${STAGINGHOSTIP}"
MASTER_HOST="${SOURCEIP}"
log "Master Host: ${SOURCEIP}"
MASTER_USER="${REPLICATION_USER}"
log "REPLICATION_USER: ${REPLICATION_USER}"
MASTER_PORT="${SOURCEPORT}"
log "MASTER_PORT: ${MASTER_PORT}"
MASTER_PASS="${REPLICATION_PASS}"

#
# Directory Paths ...
#
NEW_MOUNT_DIR="${STAGINGDATADIR}"
log "Staging Base Directory: ${NEW_MOUNT_DIR}" 

NEW_DATA_DIR="${NEW_MOUNT_DIR}/data"
NEW_LOG_DIR="${NEW_MOUNT_DIR}/log"
NEW_TMP_DIR="${NEW_MOUNT_DIR}/tmp"
NEW_MY_CNF="${NEW_MOUNT_DIR}/my.cnf"
NEW_SERVER_ID="${STAGINGSERVERID}"


###########################################################
## On Staging Server ...

# scp from source server the ${BKUP_FILE}

#
# Get master log file and position ...
#
log "LogSync Enabled: ${LOGSYNC}"
if [[ "${LOGSYNC}" == "true" ]]
then

   #head ${BKUP_FILE} -n80 | grep "MASTER_LOG_POS"
   STR=$( head ${BKUP_FILE} -n80 | grep "MASTER_LOG_POS" )
   ##echo "${STR}" 
   BINLOG_FILENAME=`echo "${STR}" | ${AWK} -F"=" '{print $2}' | cut -d"," -f1 | tr -d \'`
   BINLOG_POSITION=`echo "${STR}" | ${AWK} -F"=" '{print $3}' | cut -d";" -f1`
   log "BackupFile: ${BKUP_FILE}"
   log "MasterLogFile: ${BINLOG_FILENAME}"
   log "MasterLogPosition: ${BINLOG_POSITION}"

fi 

#
# Create Initial Database ...
#
log "MySQL Version: ${MYSQLVER}"
#MYSQLVER="5.7.20"
#MYSQLVER="5.6.28-76.1"
#10.1.32-MariaDB 
#echo ${MYSQLVER:0:3}
#5.6

log "Source --basedir=${SOURCEBASEDIR}"
log "Source --datadir=${SOURCEDATADIR}"

#
# Change MySQL Database Tables ...
#
#log "Checking for Customer Initial Database ..."
#if [[ -f "${DLPX_TOOLKIT}/install_db.zip" ]]
#then
#   log "Installing ${DLPX_TOOLKIT}/install_db.zip into ${NEW_MOUNT_DIR}"
#   unzip ${DLPX_TOOLKIT}/install_db.zip -d ${NEW_MOUNT_DIR}
#else 
#   #die "Error: Missing Initial Database zip file ... ${DLPX_TOOLKIT}/install_db.zip"
#   log "Missing Initial Database zip file ... ${DLPX_TOOLKIT}/install_db.zip"

   log "Creating Initial Database ..."

   #
   # Create Initial Database 5.7 or later ...
   #
   log "Using mysqld --initialize ..."

   log "${MYSQLD}/mysqld --initialize --user=mysql --datadir=${NEW_DATA_DIR} --log-error=${NEW_DATA_DIR}/mysqld.log"
   ${MYSQLD}/mysqld --initialize --user=mysql --datadir=${NEW_DATA_DIR} --log-error=${NEW_DATA_DIR}/mysqld.log 1>>${DEBUG_LOG} 2>&1

   PWD_LINE=`cat ${NEW_DATA_DIR}/mysqld.log | grep 'temporary password'`
   # sudo grep 'temporary password' ${NEW_DATA_DIR}/mysqld.log`
   # 2019-04-11T14:40:34.032576Z 1 [Note] A temporary password is generated for root@localhost: L0qXNZ8?C3Us
   log "init temporary password: ${PWD_LINE}"

   TMP_PWD=`echo "${PWD_LINE}" | ${AWK} -F": " '{print $2}' | xargs`
   #
   # These temporary passwords contain special characters so need to wrap in single / literal quotes ...
   #
   TMP_PWD=`echo "'"$TMP_PWD"'"`
   log "Temporary Password: ${TMP_PWD}"

   log "Staging Connection: ${STAGINGCONN}"
   RESULTS=$( buildConnectionString "${STAGINGCONN}" "${TMP_PWD}" "${STAGINGPORT}" "${STAGINGHOSTIP}" )
   echo "${RESULTS}" | jq --raw-output ".string"
   STAGING_CONN=`echo "${RESULTS}" | jq --raw-output ".string"`
   log "Staging Connection: ${STAGING_CONN}"

# fi      # end if customer install_db.zip ...

log "Creation Results: ${RESULTS}"

############################################################
##
log "Creating Staging Directories on NFS Mounted Path from Delphix ..."

mkdir -p ${NEW_DATA_DIR}
mkdir -p ${NEW_LOG_DIR}
mkdir -p ${NEW_TMP_DIR}

#
# This snippet creates a config file if one has not been provided.
# This plugin assumes that the customer will provide a my.cnf file under the toolkit directory.
# If this is not the case, change the condition.
if [[ "0" == "1" ]]
then
   log "Creating my.cnf file ..."
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

log "my.cnf file location >  ${NEW_MY_CNF}"

if [[ -f "${DLPX_TOOLKIT}/my.cnf" ]]
then
   #log "Copying Config File ${DLPX_TOOLKIT}/my.cnf ${NEW_MY_CNF}"
   #cp ${DLPX_TOOLKIT}/my.cnf ${NEW_MY_CNF}
   log "Copying Config File from ${DLPX_TOOLKIT}/my.cnf to ${NEW_MOUNT_DIR}"
   cp ${DLPX_TOOLKIT}/my.cnf ${NEW_MOUNT_DIR}
else
   log "WARNING: Missing Replication Configuration file ${DLPX_TOOLKIT}/my.cnf"
   #die "ERROR: Missing Replication Configuration file ${DLPX_TOOLKIT}/my.cnf_replication "
fi

CMD=`ls -ll "${NEW_MY_CNF}"`
log "Was my.cnf copy successful?  ${CMD}"

if [[ -f "${NEW_MY_CNF}" ]]
then
   # 
   # Replace all tabs with spaces ...
   #
   sed -i 's/\t/     /g' ${NEW_MY_CNF}

   #
   # Update Parameters ...
   #

   log "Parameter port = $TARGET_PORT" 
   CHK=`cat ${NEW_MY_CNF} | grep "^port"`
   if [[ "${CHK}" != "" ]] 
   then
      sed -i '/^port /s/port /##dlpx##port /' ${NEW_MY_CNF}
      sed -i "0,/^##dlpx##port /s/##dlpx##port /port = ${TARGET_PORT} ##dlpx##/" ${NEW_MY_CNF}
   else
      echo "port = ${TARGET_PORT}" >> ${NEW_MY_CNF}
   fi

   log "Parameter server-id = ${NEW_SERVER_ID}"
   CHK=`cat ${NEW_MY_CNF} | grep "^server-id"`
   if [[ "${CHK}" != "" ]]
   then
      sed -i '/^server-id /s/server-id /##dlpx##server-id /' ${NEW_MY_CNF}
      sed -i "0,/^##dlpx##server-id /s/##dlpx##server-id /server-id = ${NEW_SERVER_ID} ##dlpx##/" ${NEW_MY_CNF}
   else
      echo "server-id = ${NEW_SERVER_ID}" >> ${NEW_MY_CNF}
   fi

   log "Parameter binlog-format = mixed"
   CHK=`cat ${NEW_MY_CNF} | grep "^binlog-format"`
   if [[ "${CHK}" != "" ]]
   then
      sed -i '/^binlog-format /s/binlog-format /##dlpx##binlog-format /' ${NEW_MY_CNF}
      sed -i "0,/^##dlpx##binlog-format /s/##dlpx##binlog-format /binlog-format = mixed ##dlpx##/" ${NEW_MY_CNF}
   else
      echo "binlog-format = mixed" >> ${NEW_MY_CNF}
   fi

   log "Parameter log_bin"
   CHK=`cat ${NEW_MY_CNF} | grep "^log_bin"`
   if [[ "${CHK}" != "" ]]
   then
      sed -i ';^log_bin ;s;log_bin ;##dlpx##log_bin ;' ${NEW_MY_CNF}
      sed -i "0,;^##dlpx##log_bin ;s;##dlpx##log_bin ;log_bin = ${NEW_LOG_DIR}/mysql-bin ##dlpx##;" ${NEW_MY_CNF}
   else
      echo "log_bin = ${NEW_LOG_DIR}/mysql-bin" >> ${NEW_MY_CNF}
   fi

   log "Parameter relay-log = ${NEW_LOG_DIR}/mysql-relay-bin"
   CHK=`cat ${NEW_MY_CNF} | grep "^relay-log"`
   if [[ "${CHK}" != "" ]]
   then
      sed -i ';^relay-log ;s;relay-log ;##dlpx##relay-log ;' ${NEW_MY_CNF}
      sed -i "0,;^##dlpx##relay-log ;s;##dlpx##relay-log ;relay-log = ${NEW_LOG_DIR}/mysql-relay-bin ##dlpx##;" ${NEW_MY_CNF}
   else
      echo "relay-log = ${NEW_LOG_DIR}/mysql-relay-bin" >> ${NEW_MY_CNF}
   fi

   log "Parameter log-slave-update = 1"
   CHK=`cat ${NEW_MY_CNF} | grep "^log-slave-updates"`
   if [[ "${CHK}" != "" ]]
   then
      sed -i '/^log-slave-updates /s/log-slave-updates /##dlpx##log-slave-updates /' ${NEW_MY_CNF}
      sed -i "0,/^##dlpx##log-slave-updates /s/##dlpx##log-slave-updates /log-slave-updates = 1 ##dlpx##/" ${NEW_MY_CNF}
   else
      echo "log-slave-updates = 1" >> ${NEW_MY_CNF}
   fi

   log "Parameter read-only = 1"
   CHK=`cat ${NEW_MY_CNF} | grep "^read-only"`
   if [[ "${CHK}" != "" ]]
   then
      sed -i '/^read-only /s/read-only /##dlpx##read-only /' ${NEW_MY_CNF}
      sed -i "0,/^##dlpx##read-only /s/##dlpx##read-only /read-only = 1 ##dlpx##/" ${NEW_MY_CNF}
   else
      echo "read-only = 1" >> ${NEW_MY_CNF}
   fi

   log "Parameter basedir = ${SOURCEBASEDIR}"
   CHK=`cat ${NEW_MY_CNF} | grep "^basedir"`
   if [[ "${CHK}" != "" ]]
   then
      sed -i ';^basedir ;s;basedir ;##dlpx##basedir ;' ${NEW_MY_CNF}
      sed -i "0,;^##dlpx##basedir ;s;##dlpx##basedir ;basedir = ${SOURCEBASEDIR} ##dlpx##;" ${NEW_MY_CNF}
   else
      echo "basedir = ${SOURCEBASEDIR}" >> ${NEW_MY_CNF}
   fi

   log "Parameter datadir = ${NEW_DATA_DIR}"
   CHK=`cat ${NEW_MY_CNF} | grep "^datadir"`
   if [[ "${CHK}" != "" ]]
   then
      sed -i '/^datadir /s/datadir /##dlpx##datadir /' ${NEW_MY_CNF}
      sed -i "0,;^##dlpx##datadir ;s;##dlpx##datadir ;datadir = ${NEW_DATA_DIR} ##dlpx##;" ${NEW_MY_CNF}
   else
      echo "datadir = ${NEW_DATA_DIR}" >> ${NEW_MY_CNF}
   fi

   log "Parameter tmpdir = ${NEW_TMP_DIR}"
   CHK=`cat ${NEW_MY_CNF} | grep "^tmpdir"`
   if [[ "${CHK}" != "" ]]
   then
      sed -i '/^tmpdir /s/tmpdir /##dlpx##tmpdir /' ${NEW_MY_CNF}
      sed -i "0,;^##dlpx##tmpdir ;s;##dlpx##tmpdir ;tmpdir = ${NEW_TMP_DIR} ##dlpx##;" ${NEW_MY_CNF}
   else
      echo "tmpdir = ${NEW_TMP_DIR}" >> ${NEW_MY_CNF}
   fi

   log "Parameter socket = ${NEW_MOUNT_DIR}/mysql.sock"
   CHK=`cat ${NEW_MY_CNF} | grep "^socket"`
   if [[ "${CHK}" != "" ]]
   then
      sed -i '/^socket /s/socket /##dlpx##socket /' ${NEW_MY_CNF}
      sed -i "0,;^##dlpx##socket ;s;##dlpx##socket ;socket = ${NEW_MOUNT_DIR}/mysql.sock ##dlpx##;" ${NEW_MY_CNF}
   else
      echo "socket = ${NEW_MOUNT_DIR}/mysql.sock" >> ${NEW_MY_CNF}
   fi

   log "Parameter log-error = ${NEW_MOUNT_DIR}/mysqld_error.log" 
   CHK=`cat ${NEW_MY_CNF} | grep "^log-error"`
   if [[ "${CHK}" != "" ]]
   then
      sed -i '/^log-error /s/log-error /##dlpx##log-error /' ${NEW_MY_CNF}
      sed -i "0,;^##dlpx##log-error ;s;##dlpx##log-error ;log-error = ${NEW_MOUNT_DIR}/mysqld_error.log ##dlpx##;" ${NEW_MY_CNF}
   else
      echo "log-error = ${NEW_MOUNT_DIR}/mysqld_error.log" >> ${NEW_MY_CNF}
   fi

   log "Parameter pid-file = ${NEW_MOUNT_DIR}/mysqld.pid"
   CHK=`cat ${NEW_MY_CNF} | grep "^pid-file"`
   if [[ "${CHK}" != "" ]]
   then
      sed -i '/^pid-file /s/pid-file /##dlpx##pid-file /' ${NEW_MY_CNF}
      sed -i "0,;^##dlpx##pid-file ;s;##dlpx##pid-file ;pid-file = ${NEW_MOUNT_DIR}/mysql.pid ##dlpx##;" ${NEW_MY_CNF}
   else
      echo "pid-file = ${NEW_MOUNT_DIR}/mysql.pid" >> ${NEW_MY_CNF}
   fi

else 
   die "Error: Missing Customer Config File ${NEW_MY_CNF} ... see log messages above for possible errors"
fi

CMD=`ls -ll ${NEW_MOUNT_DIR}`
log "Mount Directory Contents: ${CMD}"

#
# Initial Startup ...
#
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
   die "Error: New Instance appears to not have stared, please verify ... "
fi

# Setting up symbolic link to mysql.sock # NEO
SOCKLN="${NEW_MOUNT_DIR}/mysql.sock"
REMOVE=`rm /tmp/mysql.sock`   # ignore errors
SOCK_SYM_LINK=`ln -s $SOCKLN /tmp/mysql.sock`

########################################################################
#
# Change Password for Staging Conn ...
#
CMD="${INSTALL_BIN}/mysql ${STAGING_CONN} --connect-expired-password -se \"ALTER USER 'root'@'localhost' IDENTIFIED BY ${STAGINGPASS};UPDATE mysql.user SET authentication_string=PASSWORD(${STAGINGPASS}) where USER='root';FLUSH PRIVILEGES;\""
log "Final Command to Change Password is : ${CMD}"

eval ${CMD} 1>>${DEBUG_LOG} 2>&1

#
# Update Staging Connection with supplied password ...
#
log "Staging Connection Prior to updaging password : ${STAGINGCONN}"
RESULTS=$( buildConnectionString "${STAGINGCONN}" "${STAGINGPASS}" "${STAGINGPORT}" "${STAGINGHOSTIP}" )
echo "${RESULTS}" | jq --raw-output ".string"
STAGING_CONN=`echo "${RESULTS}" | jq --raw-output ".string"`
log "============================================================"
log "Staging Connection after updating password: ${STAGING_CONN}"

########################################################################
#
# Load Source Database Export ...
#
log "============================================================"
log "Restoring Backup File "
log "============================================================"
log "${INSTALL_BIN}/mysql ******* < ${BKUP_FILE}"
log "${INSTALL_BIN}/mysql ${STAGING_CONN} < ${BKUP_FILE}"
#RESULTS=$( ${INSTALL_BIN}/mysql ${STAGING_CONN} < ${BKUP_FILE} )
#log "Restore Results: ${RESULTS}"

## Reset Master before restoring backup
##RESET_MASTER="${DLPX_TOOLKIT}/reset_master.sql"
##echo "RESET MASTER;" > ${RESET_MASTER}
CMD="${INSTALL_BIN}/mysql ${STAGING_CONN} -e \"RESET MASTER;\""
log "Reset Master Command:  ${CMD}"       # TODO REMOVE
eval ${CMD} 1>>${DEBUG_LOG} 2>&1

## Ingest Backup File
CMD="${INSTALL_BIN}/mysql ${STAGING_CONN} < ${BKUP_FILE}"
eval ${CMD} 1>>${DEBUG_LOG} 2>&1

log "====== Validating Restored Databases ======"
#RESULTS=`${INSTALL_BIN}/mysql ${STAGING_CONN} -e "show databases;"`
#log "show databases: ${RESULTS}"
CMD="${INSTALL_BIN}/mysql ${STAGING_CONN} -e \"show databases;\""
eval ${CMD} 1>>${DEBUG_LOG} 2>&1

#
# Shutting down after the backup has been ingested.
#
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

#
# Verify Database is Shutdown ...
#
PSEF=$( ps -ef | grep -E "[m]ysqld.*--port=${TARGET_PORT}" )
log "Process Status: ${PSEF}"

PSID=`echo "${PSEF}" | ${AWK} -F" " '{print $2}' | xargs`
log "Process Id: ${PSID}"

if [[ "${PSID}" != "" ]]
then
   die "ERROR: Database is not shutdown, please investigate ..."
fi

#
# Use Restored Database Password ...
#
log "============================================================"
log "Source DB Password is ${SOURCEPASS}"
log "============================================================"
if [[ "${SOURCEPASS}" != "" ]]
then
   STAGING_CONN="-udelphix1 -p${SOURCEPASS} --protocol=TCP --port=${TARGET_PORT}"
else
   STAGING_CONN="-uroot -pLandshark00! --protocol=TCP --port=${TARGET_PORT}"
fi
log "============================================================"
log "New Connection String to Staging DB >> ${STAGING_CONN}"

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
##   \"logSync\": \"${LOGSYNC}\",

startDatabase "${JSON}" "${STAGING_CONN}" "" ""

#
# Validate if Staging is started.
#
PSEF=$( ps -ef | grep -E "[m]ysqld.*--port=${TARGET_PORT}" )
log "Process Status: ${PSEF}"
PSID=`echo "${PSEF}" | ${AWK} -F" " '{print $2}' | xargs`
log "Process Id: ${PSID}"

if [[ "${PSID}" == "" ]]
then
   die "ERROR: Database did not start after password change ..."
fi

log "Validating new connection string ..."
RESULTS=`${INSTALL_BIN}/mysql ${STAGING_CONN} -e "SELECT @@BASEDIR;"`
log "Connection Test: ${RESULTS}"


# Setup SLAVE REPLICATION. 
# At this point, slave should have already started.

log "LogSync Enabled: ${LOGSYNC}"
if [[ "${LOGSYNC}" == "true" ]]
then
   #
   # Setup Slave SQL ...
   #
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

   #
   # Start Slave ...
   #
   log "Starting Slave ..."
   RESULTS=$(${INSTALL_BIN}/mysql ${STAGING_CONN} -vvv < ${TMPLOG}.sql)
   RESULTS=`cat ${TMPLOG}.out | tr '\n' '|'`
   log "Starting Slave Results: ${RESULTS}"

   #if [[ -f "${TMPLOG}.sql" ]] 
   #then
   #   rm "${TMPLOG}.sql" 2>/dev/null
   #fi
   #if [[ -f "${TMPLOG}.out" ]] 
   #then
   #   rm "${TMPLOG}.out" 2>/dev/null
   #fi

   log "Checking Slave Status ..."
   log "${INSTALL_BIN}/mysql ${STAGING_CONN} -se \"SHOW SLAVE STATUS\G\""
   RESULTS=$(${INSTALL_BIN}/mysql ${STAGING_CONN} -se "SHOW SLAVE STATUS\G")
   log "Slave Status: ${RESULTS}"

   # A parting tip: Sometimes errors occur in replication. 
   # For example, if you accidentally change a row of data on your slave. 
   # If this happens, fix the data, then run:

   #STOP SLAVE;SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1;START SLAVE;

fi    		# end if $LOGSYNC ...

 
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
env | sort  >>$DEBUG_LOG
log "------------------------- End"
exit 0