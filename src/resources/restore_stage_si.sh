#!/bin/sh
#
# Copyright (c) 2018 by Delphix. All rights reserved.
#

##DEBUG## In Delphix debug.log
#set -x

#
# Program Name ...
#
PGM_NAME='restore_stage_si.sh'

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

###########################################################
## On Staging Server ...

#
# Software Binaries ...
#
INSTALL_BIN="${SOURCEBASEDIR}/bin"
log "Binaries: ${INSTALL_BIN}"

#
# Ports ...
#
log "Source Port: ${SOURCEPORT}"
log "Staging Port: ${STAGINGPORT}"

# These passwords contain special characters so need to wrap in single / literal quotes ...
STAGINGPASS=`echo "'"${STAGINGPASS}"'"`

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

log "Creating Staging Directories on NFS Mounted Path from Delphix ..."

mkdir -p ${NEW_DATA_DIR}
mkdir -p ${NEW_LOG_DIR}
mkdir -p ${NEW_TMP_DIR}

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

log "Creating an initial MySQL instance ..."

#
# Create Initial Database 5.7 or later ...
#
log "Using mysqld --initialize ..."
# --log-error=/var/log/mysqld.log --pid-file=/var/run/mysqld/mysqld.pid --socket=/var/lib/mysql/mysql.sock
 
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

##log "Creation Results: ${RESULTS}"

log "Staging Connection: ${STAGINGCONN}"
RESULTS=$( buildConnectionString "${STAGINGCONN}" "${TMP_PWD}" "${STAGINGPORT}" )
#log "${RESULTS}"
STAGING_CONN=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".string"`
log "Staging Connection: ${STAGING_CONN}"

############################################################
##

#
# Create my.cnf file ...
#
log "Creating my.cnf file ..."
echo "[mysql]" > ${NEW_MY_CNF}
echo "server-id               = ${NEW_SERVER_ID}" >> ${NEW_MY_CNF}
echo "binlog-format           = mixed" >> ${NEW_MY_CNF}
echo "log_bin                 = ${NEW_LOG_DIR}/mysql-bin" >> ${NEW_MY_CNF}
echo "relay-log               = ${NEW_LOG_DIR}/mysql-relay-bin" >> ${NEW_MY_CNF}
#echo "log-slave-updates       = 1" >> ${NEW_MY_CNF}
#echo "read-only               = 1" >> ${NEW_MY_CNF}
echo "" >> ${NEW_MY_CNF}
echo "basedir=${SOURCEBASEDIR}" >> ${NEW_MY_CNF}
echo "datadir=${NEW_DATA_DIR}" >> ${NEW_MY_CNF}
echo "tmpdir=${NEW_TMP_DIR}" >> ${NEW_MY_CNF}
echo "socket=${NEW_MOUNT_DIR}/mysql.sock" >> ${NEW_MY_CNF}
echo "port=${STAGINGPORT}" >> ${NEW_MY_CNF}
###echo "sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES" >> ${NEW_MY_CNF}
echo "log-error=${NEW_MOUNT_DIR}/mysqld_error.log" >> ${NEW_MY_CNF}
echo "" >> ${NEW_MY_CNF}
echo "[mysqld_safe]" >> ${NEW_MY_CNF}
echo "log-error=${NEW_MOUNT_DIR}/mysqld_error.log" >> ${NEW_MY_CNF}
echo "pid-file=${NEW_MOUNT_DIR}/mysqld.pid" >> ${NEW_MY_CNF}
echo "" >> ${NEW_MY_CNF}


CMD=`ls -ll ${NEW_MOUNT_DIR}`
log "Mount Directory Contents: ${CMD}"

#
# Stop Database ... 
#
RESULTS=$( portStatus "${STAGINGPORT}" )
zSTATUS=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".status"`

if [[ "${zSTATUS}" == "ACTIVE" ]]
then
   log "Last Shutdown ..."
   stopDatabase "${RESULTS}" "${STAGING_CONN}" ""
else
   log "Database is Already Shut Down ..."
fi

#
# Initial Startup ...
#
RESULTS=$( portStatus "${STAGINGPORT}" )
zSTATUS=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".status"`
JSON="{
  \"port\": \"${STAGINGPORT}\",
  \"processId\": \"\",
  \"processCmd\": \"${MYSQLD}\",
  \"socket\": \"${NEW_MOUNT_DIR}/mysql.sock\",
  \"baseDir\": \"${SOURCEBASEDIR}\",
  \"dataDir\": \"${NEW_DATA_DIR}\",
  \"myCnf\": \"${NEW_MY_CNF}\",
  \"pidFile\": \"${NEW_MOUNT_DIR}/clone.pid\",
  \"tmpDir\": \"${NEW_TMP_DIR}\",
  \"serverId\": \"${NEW_SERVER_ID}\",
  \"logSync\": \"\",
  \"status\": \"${zSTATUS}\"
}"

# Skip LOGSYNC on initial startup ...
#  \"serverId\": \"${NEW_SERVER_ID}\",
#  \"logSync\": \"${LOGSYNC}\",

##log "JSON: ${JSON}"

## Startup ...
if [[ "${zSTATUS}" != "ACTIVE" ]]
then
   log "Initial Startup ..."
   startDatabase "${JSON}" "${STAGING_CONN}" ""
else
   log "Database is Already Started ..."
fi

#
# See if instance started ...
#
PSEF=$( ps -ef | grep -E "[m]ysqld.*--port=${STAGINGPORT}" )
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

#
# Change Password for Staging Conn ... 
# 
CMD="${INSTALL_BIN}/mysql ${STAGING_CONN} --connect-expired-password -se \"ALTER USER 'root'@'localhost' IDENTIFIED BY ${STAGINGPASS}; FLUSH PRIVILEGES;\""

log "Change Password: ${CMD}"

eval ${CMD} 1>>${DEBUG_LOG} 2>&1

########################################################################
#

log "Staging Connection: ${STAGINGCONN}"
RESULTS=$( buildConnectionString "${STAGINGCONN}" "${STAGINGPASS}" "${STAGINGPORT}" )
#log "${RESULTS}"
STAGING_CONN=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".string"`
log "Staging Connection: ${STAGING_CONN}"

log "Validating Restore Databases ..."
CMD="${INSTALL_BIN}/mysql ${STAGING_CONN} -e \"show databases;\""
eval ${CMD} 1>>${DEBUG_LOG} 2>&1

#
# Validate ...
#
PSEF=$( ps -ef | grep -E "[m]ysqld.*--port=${STAGINGPORT}" )
log "Process Status: ${PSEF}"
PSID=`echo "${PSEF}" | ${AWK} -F" " '{print $2}' | xargs`
log "Process Id: ${PSID}"

if [[ "${PSID}" == "" ]]
then
   die "ERROR: Database did not start after password change ..."
fi

log "Validating new connection string ..."
CMD="${INSTALL_BIN}/mysql ${STAGING_CONN} -e \"SELECT @@BASEDIR;\""
log "Connection Test:"
eval ${CMD} 1>>${DEBUG_LOG} 2>&1

#
# Last Shutdown otherwise the toolkit hangs here ...
#
##RESULTS=$( portStatus "${STAGINGPORT}" )
##zSTATUS=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".status"`

##if [[ "${zSTATUS}" == "ACTIVE" ]]
##then
##   log "Last Shutdown ..."
##   stopDatabase "${RESULTS}" "${STAGING_CONN}" ""
##else
##   log "Database is Already Shut Down ..."
##fi

log "Environment: "
export DLPX_LIBRARY_SOURCE=""
#export REPLICATION_PASS=""
#export STAGINGPASS=""
env | sort  >>$DEBUG_LOG
log "------------------------- End"
exit 0
