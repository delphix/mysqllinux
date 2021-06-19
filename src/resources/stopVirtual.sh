#
# Copyright (c) 2018 by Delphix. All rights reserved.
#
##DEBUG## In Delphix debug.log
set -x

#
# Program Name ...
#
PGM_NAME='stopVirtual.sh'

#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
result=`library_load`
log "Start ${PGM_NAME}"
log "Library Load Status: $result"

#
# Get Port Status ...
#
log "Database Port: ${PORT}"

VDBPASS=`echo "'"${VDBPASS}"'"`
log "VDB Connection: ${VDBCONN}"
RESULTS=$( buildConnectionString "${VDBCONN}" "${VDBPASS}" "${PORT}" )
#log "${RESULTS}"
VDB_CONN=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".string"`
log "Staging Connection: ${VDB_CONN}"

RESULTS=$( portStatus "${PORT}" )
#echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".status"
##log "Results: ${RESULTS}"

RESULTS=$($DLPX_BIN_JQ ".logSync = \"\"" <<< $RESULTS)

zPORT=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".port"`
zPSID=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".processId"`
zPSCMD=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".processCmd"`
zDATADIR=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".dataDir"`
zBASEDIR=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".baseDir"`
zMYCNF=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".myCnf"`
zPIDFILE=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".pidFile"`
zTMPDIR=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".tmpDir"`
zSTATUS=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".status"`

if [[ "${zSTATUS}" == "ACTIVE" ]] 
then
   log "Shutdown ..."
   stopDatabase "${RESULTS}" "${VDB_CONN}"
else 
   log "Database is Already Shut Down ..."
fi

#log "Environment: "
#export DLPX_LIBRARY_SOURCE=""
#export MYROOTPASS=""
#env | sort  >>$DEBUG_LOG
log "------------------------- End"
exit 0
