# Copyright (c) 2020 by Delphix. All rights reserved.
# Check if the database status is ACTIVE ... 
PGM_NAME="statusStaged.sh"             # used in log and errorLog

#Loading library.sh
eval "${DLPX_LIBRARY_SOURCE}"
result=`library_load`
log "Start ${PGM_NAME}"
log "Library Load Status: $result"

# Read Staging Database Port
TARGET_PORT="${STAGINGPORT}"
log "== STATUS =============Checking Status of Staging DB with Port: ${TARGET_PORT} ================"
if [[ "${TARGET_PORT}" == "" ]]
then
   errorLog "ERROR: Missing port from command line arguements, i.e.  ./restart.sh 3307   exiting ..."
   exit 1
fi

# Get Process using port
PSEF=$( ps -ef | grep -E "[m]ysqld.*--port=${TARGET_PORT}" )
log "Process: ${PSEF}"
PSID=`echo "${PSEF}" | awk -F" " '{print $2}'`
PSCMD=`echo "${PSEF}" | awk -F" " '{print $8}'`
log "Process Id: ${PSID}"
log "Process Command: ${PSCMD}"

# Returned Status
ACTIVE=""
if [[ "${PSID}" != "" ]]
then
   ACTIVE="ACTIVE"
else
   ACTIVE="INACTIVE"  
fi
#printf "\"${ACTIVE}\"" > "$DLPX_OUTPUT_FILE"
log "Status of Staging DB : ${ACTIVE}" 
log "--End--"
echo "$ACTIVE"
exit 0
