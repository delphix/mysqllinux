#
# Copyright (c) 2018 by Delphix. All rights reserved.
#

# Program Name ...
#
PGM_NAME='stopStagedDB.sh'

#Loading library.sh
eval "${DLPX_LIBRARY_SOURCE}"
result=`library_load`
log "Start ${PGM_NAME}"
log "Library Load Status: $result"

#
# Confirm Port ...
#
TARGET_PORT="${STAGINGPORT}"
log "Database Port: ${TARGET_PORT}"
if [[ "${TARGET_PORT}" == "" ]]
then
   die "ERROR: Missing port ${STAGINGPORT}, exiting ..."
fi

# These passwords contain special characters so need to wrap in single / literal quotes ...
STAGINGPASS=`echo "'"${STAGINGPASS}"'"`
masklog "Staging Connection: ${STAGINGCONN}"
RESULTS=$( buildConnectionString "${STAGINGCONN}" "${STAGINGPASS}" "${STAGINGPORT}" )
#log "${RESULTS}"
STAGING_CONN=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".string"`
masklog "Staging Connection: ${STAGING_CONN}"

#
# Get Process ...
#
RESULTS=$( portStatus "${TARGET_PORT}" )
zSTATUS=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".status"`
RESULTS=$($DLPX_BIN_JQ ".logSync = \"$LOGSYNC\"" <<< $RESULTS)

if [[ "${zSTATUS}" == "ACTIVE" ]]
then
   log "Shutdown ..."
   stopDatabase "${RESULTS}" "${STAGING_CONN}" ""
else
   log "Database is Already Shut Down ..."
   echo "STAGING STOPPED"
fi

#log "Environment: "
#export DLPX_LIBRARY_SOURCE=""
#export REPLICATION_PASS=""
#export STAGINGPASS=""
#env | sort  >>$DEBUG_LOG
log "End"
exit 0
