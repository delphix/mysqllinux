#
set -x 
PGM_NAME='startVirtual.sh'

#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
result=`library_load`
log "Start ${PGM_NAME}"
log "Library Load Status: $result"

VDBPASS=`echo "'"${VDBPASS}"'"`
log "VDB Connection: ${VDBCONN}"
RESULTS=$( buildConnectionString "${VDBCONN}" "${VDBPASS}" "${PORT}" )
#log "${RESULTS}"
VDB_CONN=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".string"`
log "Staging Connection: ${VDB_CONN}"

#
# Get Port Status ...
#
log "Database Port: ${PORT}"
RESULTS=$( portStatus "${PORT}" )
#echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".status"
zSTATUS=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".status"`

NEW_MOUNT_DIR="${DLPX_DATA_DIRECTORY}"
log "Staging Base Directory: ${NEW_MOUNT_DIR}"

NEW_DATA_DIR="${NEW_MOUNT_DIR}/data"
NEW_LOG_DIR="${NEW_MOUNT_DIR}/log"
NEW_TMP_DIR="${NEW_MOUNT_DIR}/tmp"
NEW_MY_CNF="${NEW_MOUNT_DIR}/my.cnf"

JSON="{
  \"port\": \"${PORT}\",
  \"processId\": \"\",
  \"processCmd\": \"${MYSQLD}\",
  \"socket\": \"${NEW_MOUNT_DIR}/mysql.sock\",
  \"baseDir\": \"${MYBASEDIR}\",
  \"dataDir\": \"${NEW_DATA_DIR}\",
  \"myCnf\": \"${NEW_MY_CNF}\",
  \"serverId\": \"${SERVERID}\",
  \"pidFile\": \"${NEW_MOUNT_DIR}/clone.pid\",
  \"tmpDir\": \"${NEW_MOUNT_DIR}/tmp\",
  \"logSync\": \"\",
  \"status\": \"${zSTATUS}\"
}"

##log "JSON: ${JSON}"

#
# Startup ...
# 
if [[ "${zSTATUS}" != "ACTIVE" ]]
then
   log "Startup ..."
   startDatabase "${JSON}" "${VDB_CONN}"
else
   log "Database is Already Started ..."
fi

#log "Environment: "
#export DLPX_LIBRARY_SOURCE=""
#export MYROOTPASS=""
#env | sort  >>$DEBUG_LOG
log "------------------------- End"
exit 0
