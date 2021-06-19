#
# Copyright (c) 2018 by Delphix. All rights reserved.
#

# Check if the output of status contains the string "running"

##DEBUG## In Delphix debug.log
#set -x

#
# Program Name ...
#
PGM_NAME="statusVirtual.sh"             # used in log and errorLog

#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
result=`library_load`
log "Start ${PGM_NAME}"
log "Library Load Status: $result"

#
# Get Database Port ...
#
TARGET_PORT="${PORT}"
log "Database Port: ${TARGET_PORT}"
if [[ "${TARGET_PORT}" == "" ]]
then
   die "ERROR: Missing port from command line arguements, [command] --port=3307  exiting ..."
fi

#
# Get Process ...
#
RESULTS=$( portStatus "${TARGET_PORT}" )
####log "Results: ${RESULTS}"
zPORT=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".port"`
zPSID=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".processId"`
zPSCMD=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".processCmd"`
zSTATUS=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".status"`
log "Status Process Id: ${zPSID}"
log "Status Process Command: ${zPSCMD}"

# 
# Returned Status ...
#
ACTIVE=""
if [[ "${zSTATUS}" == "ACTIVE" ]]
then
   ACTIVE="ACTIVE"
else
   ACTIVE="INACTIVE"  
fi
printf "\"${ACTIVE}\"" > "$DLPX_OUTPUT_FILE"
log "Output: ${ACTIVE}" 

#log "Environment: "
#export DLPX_LIBRARY_SOURCE=""
#env | sort  >>$DEBUG_LOG
log "------------------------- End"
exit 0
