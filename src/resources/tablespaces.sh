# 
# Copyright (c) 2018 by Delphix. All rights reserved.
#

##DEBUG## In Delphix debug.log
#set -x

#
# Program Name ...
#
PGM_NAME='tablespaces.sh'

#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
result=`hey`
log "------------------------- Start"
log "Library Loaded ... hey $result"

who=`whoami`
log "whoami: $who"

AWK=`which awk`
log "awk: ${AWK}"

DT=`date '+%Y%m%d%H%M%S'`

NEW_MOUNT_DIR="${STAGINGDATADIR}"
log "Staging Base Directory: ${NEW_MOUNT_DIR}"

NEW_DATA_DIR="${NEW_MOUNT_DIR}/data"
NEW_LOG_DIR="${NEW_MOUNT_DIR}/log"
NEW_TMP_DIR="${NEW_MOUNT_DIR}/tmp"

#
# Source Variables ...
#
#SOURCE_CONN="-uroot -pdelphix --protocol=TCP --port=3306"

SOURCEPASS=`echo "'"${SOURCEPASS}"'"`
log "Source Connection: ${SOURCECONN}"
RESULTS=$( buildConnectionString "${SOURCECONN}" "${SOURCEPASS}" "${SOURCEPORT}" )
#log "${RESULTS}"
SOURCE_CONN=`echo "${RESULTS}" | jq --raw-output ".string"`
log "Source Connection: ${SOURCE_CONN}"

SOURCE_DATA_DIR="${SOURCEDATADIR}" 				# "/usr/local/mysql/data"
SOURCE_BASE_DIR="${SOURCEBASEDIR}" 				# "/usr/local/mysql"
SOURCE_DB="${SOURCEDATABASE}"					# "delphixdb"
SOURCE_TABLES="${SOURCETABLES}"					# "ALL" "employees,patient,patient_details,medical_records"

#
# Target Variables ...
# 
#TARGET_CONN="-uroot -pdelphix --protocol=TCP --port=3307"

STAGINGPASS=`echo "'"${STAGINGPASS}"'"`
log "Staging Connection: ${STAGINGCONN}"
RESULTS=$( buildConnectionString "${STAGINGCONN}" "${STAGINGPASS}" "${STAGINGPORT}" )
#log "${RESULTS}"
TARGET_CONN=`echo "${RESULTS}" | jq --raw-output ".string"`
log "Staging Connection: ${TARGET_CONN}"

#TARGET_DATA_DIR="/mnt/provision/my_stage/data"
TARGET_DATA_DIR="${STAGINGDATADIR}"/data
TARGET_BASE_DIR="${STAGINGBASEDIR}"

###TARGET_VDB="mydb"   # Doesn't work with Tablespaces 

BACKUP_FILE="${NEW_TMP_DIR}/schemad.sql"

SCP_FROM="${SCPUSER}@${SOURCEIP}" 				# "delphix@172.16.160.133"
SCP_DEST="${SCPUSER}@${STAGINGHOSTIP}"       # "delphix@172.16.160.133"
SCP_PASS="${SCPPASS}"						      # "delphix"

##########################################
## No Changes Required Below this Point ##
##########################################

#
# Backup previous backup ...
#
if [[ -f "${BACKUP_FILE}" ]]
then
   cp ${BACKUP_FILE} ${BACKUP_FILE}_${DT}
fi

#
# Source Tables Array ...
#
if [[ "${SOURCE_TABLES}" == "ALL" ]] || [[ "${SOURCE_TABLES}" == "all" ]] || [[ "${SOURCE_TABLES}" == "All" ]]
then
   CMD="${SOURCE_BASE_DIR}/bin/mysql ${SOURCE_CONN} -se \"use ${SOURCE_DB};show tables;\" > mytables.txt"
   eval ${CMD} 1>>${DEBUG_LOG} 2>&1
   mapfile -t array < mytables.txt
else
   array=(${SOURCE_TABLES//,/ })
fi
## Debug ## for i in "${!array[@]}"; do log "$i=>${array[i]}"; done

#
# Build DDL Commands for Each Table ...
#
DELIM=""
FLUSH=""
ALTER_DIS=""
ALTER_IMP=""
TALBES_STR=""
set -f                      # avoid globbing (expansion of *).
for i in "${!array[@]}"
do
    log "$i=>${array[i]}"
    TBLS="${TBLS} ${aarray[i]}"
    ##FLUSH="${FLUSH}FLUSH TABLES ${array[i]} FOR EXPORT;"     # Use single statement, see below FLUSH value
    ALTER_DIS="${ALTER_DIS}ALTER TABLE ${array[i]} DISCARD TABLESPACE;"
    ALTER_IMP="${ALTER_IMP}ALTER TABLE ${array[i]} IMPORT TABLESPACE;"
    TABLES_STR="${TABLES_STR}${DELIM}${array[i]}"
    DELIM=","
done

FLUSH="FLUSH TABLES ${TABLES_STR} FOR EXPORT;"
log "${TBLS}"
log "${FLUSH}"
log "${ALTER_DIS}"
log "${ALTER_IMP}"

## Backup Database DDL, Includes create database command ...
log "Source Export DDL ..."
CMD="${SOURCE_BASE_DIR}/bin/mysqldump ${SOURCE_CONN} --no-data --set-gtid-purged=OFF --databases ${SOURCE_DB} > ${BACKUP_FILE}"
eval ${CMD} 1>>${DEBUG_LOG} 2>&1 

## Backup just specific tables ...
##${SOURCE_BASE_DIR}/bin/mysqldump ${SOURCE_CONN} --no-data ${SOURCE_DB} ${TBLS} > ${BACKUP_FILE}

#Doesn't work with tablespaces ...
#log "Changing Database Names in Backup File ..."
##log "sed -i \"s/\`${STAGED_DBNAME}\`/\`${VDBNAME}\`/g\" ${BACKUP_FILE}"
#sed -i "s/\`${SOURCE_DB}\`/\`${TARGET_VDB}\`/g" ${BACKUP_FILE}

## Target ...
log "Target Import DDL ..."
CMD="${TARGET_BASE_DIR}/bin/mysql ${TARGET_CONN} < ${BACKUP_FILE}"
eval ${CMD} 1>>${DEBUG_LOG} 2>&1

log "Target Alter Tables Discard ..."
CMD="${TARGET_BASE_DIR}/bin/mysql ${TARGET_CONN} -e \"use ${SOURCE_DB};${ALTER_DIS}\""
eval ${CMD} 1>>${DEBUG_LOG} 2>&1

## Source ...
log "Source Flush Tables ..."
CMD="${SOURCE_BASE_DIR}/bin/mysql ${SOURCE_CONN} -e \"use ${SOURCE_DB};${FLUSH}\""
eval ${CMD} 1>>${DEBUG_LOG} 2>&1

## scp ...
## SCP_CMD="${SCP_CMD}sshpass -p "${SCP_PASS}" scp ${SOURCE_DATA_DIR}/${SOURCE_DB}/${array[i]}.{ibd,cfg} ${SCP_DEST}:${TARGET_DATA_DIR}/${SOURCE_DB}/"
log "scp file(s)..."
for i in "${!array[@]}"
do
   # scp on source ...
   #sshpass -p "${SCP_PASS}" scp ${SOURCE_DATA_DIR}/${SOURCE_DB}/${array[i]}.ibd ${SCP_DEST}:${TARGET_DATA_DIR}/${SOURCE_DB}/
   # scp on staging/target ...
   CMD="scp ${SCP_FROM}:${SOURCE_DATA_DIR}/${SOURCE_DB}/${array[i]}.ibd ${TARGET_DATA_DIR}/${SOURCE_DB}"
   log "SCP: ${CMD}"
   eval ${CMD} 1>>${DEBUG_LOG} 2>&1
done

## Source ...
log "Source Unload Tables ..."
CMD="${SOURCE_BASE_DIR}/bin/mysql ${SOURCE_CONN} -e \"use ${SOURCE_DB};UNLOCK TABLES;\""
eval ${CMD} 1>>${DEBUG_LOG} 2>&1

## Target Import ...
log "Target Alter Table Import ..."
CMD="${TARGET_BASE_DIR}/bin/mysql ${TARGET_CONN} -e \"use ${SOURCE_DB};${ALTER_IMP}\""
eval ${CMD} 1>>${DEBUG_LOG} 2>&1

log "Environment: "
export DLPX_LIBRARY_SOURCE=""
export STAGINGPASS=""
env | sort  >>$DEBUG_LOG
log "------------------------- End"
exit 0
