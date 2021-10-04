#
# Copyright (c) 2018 by Delphix. All rights reserved.
#

##DEBUG## In Delphix debug.log
#set -x

#
# Program Name ...
#
PGM_NAME='provision.sh'

#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
result=`library_load`
log "Start ${PGM_NAME}"
log "Library Load Status: $result"

DT=`date '+%Y%m%d%H%M%S'`

printParams

TARGET_PORT=${PORT}
log "Target Port: ${TARGET_PORT}"
log "Config Params: ${MYCONFIG}"
# Customer Config File Parameters ...
log "Customer my.cnf Parameters: ${MYCONFIG}"
LINES=""
if [[ "${MYCONFIG}" != "" ]]
then
   #LINES=`${XARGS} -n 2 printf "%s = %s\n" <<< ${MYCONFIG}`
   LINES=${MYCONFIG}
fi
log "my.cnf lines: ${LINES}"

#
# Get from Snapshot
# Staging Details from snapshot data ...
#
log "======== Logging Snapshot Information:=========="
#log "${SNAPSHOT_METADATA}"
#STAGED_HOST=`echo "${SNAPSHOT_METADATA}" | $DLPX_BIN_JQ --raw-output '.snapHost'`
#STAGED_PORT=`echo "${SNAPSHOT_METADATA}" | $DLPX_BIN_JQ --raw-output '.snapPort'`
#STAGED_DATADIR=`echo "${SNAPSHOT_METADATA}" | $DLPX_BIN_JQ --raw-output '.snapDataDir'`
#CONFIG_BASEDIR=`echo "${SNAPSHOT_METADATA}" | $DLPX_BIN_JQ --raw-output '.snapBaseDir'`
#STAGED_ROOT_PASS=`echo "${SNAPSHOT_METADATA}" | $DLPX_BIN_JQ --raw-output '.snapPass'`
#STAGED_BACKUP=`echo "${SNAPSHOT_METADATA}" | $DLPX_BIN_JQ --raw-output '.snapBackup'`

log "Snap Staging Port: ${STAGED_PORT}"
log "Snap Staging DataDir: ${STAGED_DATADIR}"
log "Snap Config BaseDir: ${CONFIG_BASEDIR}"
#log "Snap Staging Root Password: ${STAGED_ROOT_PASS}"
log "Snap Staged Backup: ${STAGED_BACKUP}"

INSTALL_PATH="${CONFIG_BASEDIR}"

log "port test: $STAGED_PORT ...$PORT"
log "basedir: ... $CONFIG_BASEDIR ...INSTALL_PATH"
##log "pass test: $STAGED_ROOT_PASS ... $MYROOTPASS. "

INSTALL_BIN="${INSTALL_PATH}/bin"
log "Binaries: ${INSTALL_BIN}"

if [[ ! -f "${INSTALL_BIN}"/mysql ]]
then
   terminate "Error: ${INSTALL_BIN}/mysql is invalid" 10
fi
VDBPASS=`echo "'"${VDBPASS}"'"`
masklog "VDB Connection: ${VDBCONN}"
RESULTS=$( buildConnectionString "${VDBCONN}" "${VDBPASS}" "${PORT}" )
#log "${RESULTS}"
VDB_CONN=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".string"`
masklog "VDB Connection: ${VDB_CONN}"

NEW_MOUNT_DIR="${DLPX_DATA_DIRECTORY}"
NEW_DATA_DIR="${NEW_MOUNT_DIR}/data"
NEW_LOG_DIR="${NEW_MOUNT_DIR}/log"
NEW_TMP_DIR="${NEW_MOUNT_DIR}/tmp"
NEW_MY_CNF="${NEW_MOUNT_DIR}/my.cnf"

log "Mount Directory: ${NEW_MOUNT_DIR}"
log "ServerId: ${SERVERID}"

###########################################################
## On Target Server ...
log "Source --basedir=${CONFIG_BASEDIR}"
# Create Initial Database ...
log "MySQL Version: ${MYSQLVER}"
if [[ "${MYSQLVER:0:3}" == "5.6" ]]
then
   die "MySQL ${MYSQLVER} is not supported."
fi

# Create my.cnf file
#NEW_MY_CNF="my.cnf"
log "Creating my.cnf file ..."
echo "[mysqld]" > ${NEW_MY_CNF}
echo "server-id         = ${SERVERID}" >> ${NEW_MY_CNF}
echo "basedir		= ${CONFIG_BASEDIR}" >> ${NEW_MY_CNF}
echo "datadir		= ${NEW_DATA_DIR}" >> ${NEW_MY_CNF}
echo "tmpdir		= ${NEW_TMP_DIR}" >> ${NEW_MY_CNF}
echo "socket		= ${NEW_MOUNT_DIR}/mysql.sock" >> ${NEW_MY_CNF}
echo "port		= ${TARGET_PORT}" >> ${NEW_MY_CNF}
##echo "log_bin		= ${NEW_LOG_DIR}/mysql-bin" >> ${NEW_MY_CNF}
##echo "skip-start-slave" >> ${NEW_MY_CNF}
##echo "sql_mode		= NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES" >> ${NEW_MY_CNF}
echo "log-error         = ${NEW_MOUNT_DIR}/mysqld_error.log" >> ${NEW_MY_CNF}
echo "pid-file          = ${NEW_MOUNT_DIR}/mysqld.pid" >> ${NEW_MY_CNF}

echo "${LINES}" >> ${NEW_MY_CNF}

echo "" >> ${NEW_MY_CNF}
echo "[mysqld_safe]" >> ${NEW_MY_CNF}
echo "log-error		= ${NEW_MOUNT_DIR}/mysqld_error.log" >> ${NEW_MY_CNF}
echo "pid-file		= ${NEW_MOUNT_DIR}/mysqld.pid" >> ${NEW_MY_CNF}
echo "" >> ${NEW_MY_CNF}

CMD=`ls -llR ${NEW_MOUNT_DIR}`
log "${NEW_MOUNT_DIR}"
log "${CMD}"

# Change MySQL Database Tables ...
log "Checking for Customer Security ..."
if [[ -f "${DLPX_TOOLKIT}/mysql_db_tables.zip" ]]
then
   log "Replacing ${NEW_DATA_DIR}/mysql with Customers Security ${DLPX_TOOLKIT}/mysql_db_tables.zip"
   CMD="mv ${NEW_DATA_DIR}/mysql /tmp/mysql_orig"
   ${CMD} </dev/null >/dev/null 2>&1 & disown "$!"
   sleep 2
   CMD="unzip ${DLPX_TOOLKIT}/mysql_db_tables.zip -d ${NEW_DATA_DIR}"
   log "Restoring ...  ${CMD}"
   ${CMD} </dev/null >/dev/null 2>&1 & disown "$!"
   sleep 2
   log "Restoring Security Done"
fi

# Initial Instance Startup ...
log "Initial Instance Startup ..."
RESULTS=$( portStatus "${PORT}" )
zSTATUS=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".status"`

JSON="{
  \"port\": \"${TARGET_PORT}\",
  \"processId\": \"\",
  \"processCmd\": \"${MYSQLD}\",
  \"socket\": \"${NEW_MOUNT_DIR}/mysql.sock\",
  \"baseDir\": \"${CONFIG_BASEDIR}\",
  \"dataDir\": \"${NEW_DATA_DIR}\",
  \"myCnf\": \"${NEW_MOUNT_DIR}/my.cnf\",
  \"serverId\": \"${SERVERID}\",
  \"pidFile\": \"${NEW_MOUNT_DIR}/clone.pid\",
  \"tmpDir\": \"${NEW_TMP_DIR}\",
  \"logSync\": \"\",
  \"status\": \"${zSTATUS}\"
}"

#  Start the Database
#  DO NOT Start Slave
if [[ "${zSTATUS}" != "ACTIVE" ]]
then
   log "Starting up VDB"
   startDatabase "${JSON}" "${VDB_CONN}" " " "NO"
else
   log "Database is Already Started ..."
fi

# ig vdb provision issue / Add sleep time for db to start
log "Forced hibernate for 120s. Waiting for database to be online."
sleep 120
log "Waking from hibernation. Resuming provision."

log "Reset Slave Status for VDB"
log "Reset Command: stop slave;CHANGE MASTER TO MASTER_HOST=' ';reset slave all;"
CMD="${INSTALL_BIN}/mysql ${VDB_CONN} -e \"stop slave;CHANGE MASTER TO MASTER_HOST=' ';reset slave all;\""
eval ${CMD} 1>>${DEBUG_LOG} 2>&1
sleep 4

#
# Stop ...
#
RESULTS=$( portStatus "${PORT}" )
zSTATUS=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".status"`
RESULTS=$($DLPX_BIN_JQ ".logSync = \"\"" <<< $RESULTS)

log "zStatus: ${zSTATUS}"
if [[ "${zSTATUS}" == "ACTIVE" ]]
then
   log "Shutdown after Initial Database Creation ..."
   stopDatabase "${RESULTS}" "${VDB_CONN}"
else
   log "Database is Already Shut Down ..."
fi

log "Forced hibernate for 10s. Waiting for database to be shutdown."
sleep 10
log "Waking from hibernation. Resuming."

#  Second StartUp
#  Do Not Start Slave
RESULTS=$( portStatus "${PORT}" )
zSTATUS=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".status"`
if [[ "${zSTATUS}" != "ACTIVE" ]]
then
   log " Starting Virtual DB for the Second Time"
   startDatabase "${JSON}" "${VDB_CONN}" " " "NO"
else
   log "Database is Already Started ..."
fi
#
# Output ...
#
prettyName="MySQL-VDB-${TARGET_PORT}"

outputJSON='{}'
outputJSON=$($DLPX_BIN_JQ ".dataDir = $(jqQuote "$DLPX_DATA_DIRECTORY")" <<< "$outputJSON")
outputJSON=$($DLPX_BIN_JQ ".port = $(jqQuote "$PORT")"  <<< "$outputJSON")
outputJSON=$($DLPX_BIN_JQ ".baseDir = $(jqQuote "$CONFIG_BASEDIR")" <<< "$outputJSON")
outputJSON=$($DLPX_BIN_JQ ".dbName = $(jqQuote "$prettyName")" <<< "$outputJSON")

printf "$outputJSON" > "$DLPX_OUTPUT_FILE"
log "Output: $outputJSON"
echo "${prettyName}"
#log "Environment: "
#export DLPX_LIBRARY_SOURCE=""
#export REPLICATION_PASS=""
#export SNAPSHOT_METADATA=""
#export STAGINGPASS=""
#env | sort  >>$DEBUG_LOG
log "End"
exit 0
