#!/bin/sh
#
# Copyright (c) 2018 by Delphix. All rights reserved.
# Program Name
PGM_NAME='restore_stage_bi.sh'

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

# Software Binaries ...
INSTALL_BIN="${SOURCEBASEDIR}/bin"
log "Binaries: ${INSTALL_BIN}"

# Ports
SOURCE_PORT=${SOURCEPORT}
TARGET_PORT=${STAGINGPORT}
log "Source Port: ${SOURCE_PORT}"
log "Staging Port: ${TARGET_PORT}"
#
# Staging Connection for Install/Configuration ...
#
STAGINGPASS=`echo "'"${STAGINGPASS}"'"`
masklog "Staging Connection: ${STAGINGCONN}"
RESULTS=$( buildConnectionString "${STAGINGCONN}" "${STAGINGPASS}" "${STAGINGPORT}" "${STAGINGHOSTIP}" )
STAGING_CONN=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".string"`
masklog "Staging Connection: ${STAGING_CONN}"

# Directory Paths
NEW_MOUNT_DIR="${STAGINGDATADIR}"
log "Staging Base Directory: ${NEW_MOUNT_DIR}"
NEW_DATA_DIR="${NEW_MOUNT_DIR}/data"
NEW_LOG_DIR="${NEW_MOUNT_DIR}/log"
NEW_TMP_DIR="${NEW_MOUNT_DIR}/tmp"
NEW_MY_CNF="${NEW_MOUNT_DIR}/my.cnf"
NEW_SERVER_ID="${STAGINGSERVERID}"

# Create Initial Database
log "MySQL Version: ${MYSQLVER}"

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

# Create Initial Database 5.7 or later ...
log "Creating Initial Database using mysqld --initialize"

log "${MYSQLD}/mysqld --initialize --user=mysql --datadir=${NEW_DATA_DIR} --log-error=${NEW_DATA_DIR}/mysqld.log"
${MYSQLD}/mysqld --initialize --user=mysql --datadir=${NEW_DATA_DIR} --log-error=${NEW_DATA_DIR}/mysqld.log 1>>${DEBUG_LOG} 2>&1

PWD_LINE=`cat ${NEW_DATA_DIR}/mysqld.log | grep 'temporary password'`
TMP_PWD=`echo "${PWD_LINE}" | ${AWK} -F": " '{print $2}' | xargs`

# These temporary passwords contain special characters so need to wrap in single / literal quotes ...
TMP_PWD=`echo "'"$TMP_PWD"'"`
masklog "Staging Connection: ${STAGINGCONN}"
RESULTS=$( buildConnectionString "${STAGINGCONN}" "${TMP_PWD}" "${STAGINGPORT}" "${STAGINGHOSTIP}" )
STAGING_CONN=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".string"`
masklog "Staging Connection: ${STAGING_CONN}"

############################################################
##
log "Creating Staging Directories on NFS Mounted Path from Delphix ..."

mkdir -p ${NEW_DATA_DIR}
mkdir -p ${NEW_LOG_DIR}
mkdir -p ${NEW_TMP_DIR}

log "my.cnf file location >  ${NEW_MY_CNF}"
if [[ -f "${DLPX_TOOLKIT}/my.cnf" ]]
then
   log "Copying Customer Config File from ${DLPX_TOOLKIT}/my.cnf to ${NEW_MOUNT_DIR}"
   cp ${DLPX_TOOLKIT}/my.cnf ${NEW_MOUNT_DIR}

   CMD=`ls -ll "${NEW_MY_CNF}"`
   log "Was my.cnf copy successful?  ${CMD}"
else
   log "WARNING: Missing Customer Configuration file ${DLPX_TOOLKIT}/my.cnf"
   # This snippet creates a config file if one has not been provided.
   log "Delphix will create my.cnf file"
   echo "[mysql]" > ${NEW_MY_CNF}
   #echo "server-id               = ${NEW_SERVER_ID}" >> ${NEW_MY_CNF}
   #echo "binlog-format           = mixed" >> ${NEW_MY_CNF}
   #echo "log_bin                 = ${NEW_LOG_DIR}/mysql-bin" >> ${NEW_MY_CNF}
   #echo "relay-log               = ${NEW_LOG_DIR}/mysql-relay-bin" >> ${NEW_MY_CNF}
   #echo "log-slave-updates       = 1" >> ${NEW_MY_CNF}
   #echo "read-only               = 1" >> ${NEW_MY_CNF}
   #echo "" >> ${NEW_MY_CNF}
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

CMD=`ls -ll "${NEW_MY_CNF}"`
log "Does my.cnf exist?  ${CMD}"

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

## Initial startup just involves starting the DB
if [[ "${zSTATUS}" != "ACTIVE" ]]
then
   log "Initial Database Startup. Passing NO for START SLAVE"
   startDatabase "${JSON}" "${STAGING_CONN}" " " "NO"
else
   log "Database is Already Started"
fi

#
# See if instance started ...
#
PSEF=$( ps -ef | grep -E "[m]ysqld.*--port=${TARGET_PORT}" )
log "Process Status: ${PSEF}"

PSID=`echo "${PSEF}" | ${AWK} -F" " '{print $2}' | xargs`
log "Process Id: ${PSID}"

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
# Change Password for Staging Conn ...
CMD="${INSTALL_BIN}/mysql ${STAGING_CONN} --connect-expired-password -se \"ALTER USER 'root'@'localhost' IDENTIFIED BY ${STAGINGPASS};UPDATE mysql.user SET authentication_string=PASSWORD(${STAGINGPASS}) where USER='root';FLUSH PRIVILEGES;\""
CMDLOG="${INSTALL_BIN}/mysql ${STAGING_CONN} --connect-expired-password -se \"ALTER USER 'root'@'localhost' IDENTIFIED BY '********';UPDATE mysql.user SET authentication_string=PASSWORD('********') where USER='root';FLUSH PRIVILEGES;\""
masklog "Final Command to Change Password is : ${CMDLOG}"
command_runner "${CMD}" 5

#eval ${CMD} 1>>${DEBUG_LOG} 2>&1

# Update Staging Connection with supplied password ...
masklog "Staging Connection Prior to updating password : ${STAGINGCONN}"
RESULTS=$( buildConnectionString "${STAGINGCONN}" "${STAGINGPASS}" "${STAGINGPORT}" "${STAGINGHOSTIP}" )
STAGING_CONN=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".string"`
log "============================================================"
masklog "Staging Connection after updating password: ${STAGING_CONN}"

#Adding the staging delphix user to new instance
CMD="${INSTALL_BIN}/mysql ${STAGING_CONN} -e \"USE mysql;CREATE USER '${SOURCEUSER}'@'localhost' identified by '${SOURCEPASS}'\""
command_runner "${CMD}" 12

#Adding user privileges. Failure is silent. We move on even if this fails.
CMD="${INSTALL_BIN}/mysql ${STAGING_CONN} -e \"USE mysql;GRANT SELECT, SHUTDOWN, SUPER, RELOAD, REPLICATION CLIENT,REPLICATION SLAVE,SHOW VIEW, EVENT, TRIGGER on *.* to '${SOURCEUSER}'@'localhost';FLUSH PRIVILEGES;\""
masklog "Granting privileges command: ${CMD}"
return_msg=$(eval ${CMD} 2>&1 1>&2 > /dev/null)
return_code=$?
log "Return Status: ${return_code}"
if [ $return_code != 0 ]; then
  errorlog "Unable to grant required permissions to delphix database user. This may have to be done manually"
fi

# Shutting down after user creation
log "============================================================"
log "Shutdown after password change and new user creation"
log "============================================================"
RESULTS=$( portStatus "${TARGET_PORT}" )
RESULTS=$($DLPX_BIN_JQ ".logSync = \"\"" <<< $RESULTS)
zSTATUS=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".status"`
if [[ "${zSTATUS}" == "ACTIVE" ]]
then
   log "Stopping Database ..."
   stopDatabase "${RESULTS}" "${STAGING_CONN}" ""
else
   log "Database is Already Shut Down"
fi

# Verify Database is Shutdown ...
PSEF=$( ps -ef | grep -E "[m]ysqld.*--port=${TARGET_PORT}" )
log "Process Status: ${PSEF}"

PSID=`echo "${PSEF}" | ${AWK} -F" " '{print $2}' | xargs`
log "Process Id: ${PSID}"

if [[ "${PSID}" != "" ]]
then
   die "ERROR: Database is not shutdown, please investigate"
fi

# Restarting database
log "====================================================================="
log "Updating staging connection to use the provided username and password"
log "====================================================================="
if [[ "${SOURCEPASS}" != "" ]]
then
   STAGING_CONN="-u${SOURCEUSER} -p'${SOURCEPASS}' --protocol=TCP --port=${TARGET_PORT}"
else
   errorlog "Staging Password is not available. Delphix maybe unable to manage this MySQL."
   STAGING_CONN="-uroot -pLandshark00! --protocol=TCP --port=${TARGET_PORT}"
fi
log "============================================================"
masklog "New Connection String to Staging DB >> ${STAGING_CONN}"

#
# Start Database
#
log "Starting staging after first shutdown."
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

startDatabase "${JSON}" "${STAGING_CONN}" " " "NO"

# Validate if Staging is started.
PSEF=$( ps -ef | grep -E "[m]ysqld.*--port=${TARGET_PORT}" )
log "Process Status: ${PSEF}"

PSID=`echo "${PSEF}" | ${AWK} -F" " '{print $2}' | xargs`
log "Process Id: ${PSID}"

if [[ "${PSID}" == "" ]]
then
   terminate "ERROR: Backup Ingestion Staging DB did not start after first shutdown.Cannot continue." 3
fi

log "Validating new connection string"
  #RESULTS=`${INSTALL_BIN}/mysql ${STAGING_CONN} -e "SELECT @@BASEDIR;"`
  #log "Connection Test: ${RESULTS}"

CMD="${INSTALL_BIN}/mysql ${STAGING_CONN} -e \"SELECT @@BASEDIR;\""
masklog "Connection Test: ${CMD}"
command_runner "${CMD}" 11

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

log "Environment:"
export DLPX_LIBRARY_SOURCE=""
export STAGINGPASS=""
env | grep -v 'STAGINGPASS' | sort >>$DEBUG_LOG
log "End"
echo "Staging Started"
exit 0
