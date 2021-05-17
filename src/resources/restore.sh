#!/bin/sh
#
# Copyright (c) 2018 by Delphix. All rights reserved.
#

##DEBUG## In Delphix debug.log
#set -x

#
# Program Name ...
#
PGM_NAME='restore.sh'

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
# Which Backup to Use ...
#
if [[ "${BACKUP_PATH}" == "" ]]
then

   #
   # No Backup Provided, let's generate one ...
   #

   #
   # Software Binaries must exist in the software install basedir ...
   #
   INSTALL_BIN="${SOURCEBASEDIR}/bin"
   log "Source Binaries: ${INSTALL_BIN}"

   #
   # Ports ...
   #
   log "Source Port: ${SOURCEPORT}"
   log "Staging Port: ${STAGINGPORT}"

   #
   # Backup File Location ...
   #
   BKUP_FILE="/tmp/dump_${SOURCEPORT}.sql"
   if [[ -f "${BKUP_FILE}" ]]
   then
      mv ${BKUP_FILE} ${BKUP_FILE}_${DT}
   fi

   # 
   # Source Connection for Backup ...
   #
   log "Source Connection: ${SOURCECONN}"
   RESULTS=$( buildConnectionString "${SOURCECONN}" "${SOURCEPASS}" "${SOURCEPORT}" "${SOURCEIP}" )
   log "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".string"
   SOURCE_CONN=`echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".string"`
   log "New Conn: ${SOURCE_CONN}"

   log "Source Backup Host: ${SOURCEIP}"

   ###########################################################
   ## On Source Server ...

   #
   # Backup ...
   #
   log "Starting Backup ..."

   if [[ "1" == "0" ]] 
   then

      #
      # No Replication Backup ...
      #

      SQL="SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN"
      SQL="${SQL} ('mysql','information_schema','performance_schema')"
 
      DBLISTFILE=/tmp/DatabasesToDump_$$.txt
      ${INSTALL_BIN}/mysql ${SOURCE_CONN} -ANe"${SQL}" > ${DBLISTFILE}
 
      DBLIST=""
      for DB in `cat ${DBLISTFILE}` ; do DBLIST="${DBLIST} ${DB}" ; done

      MYSQLDUMP_OPTIONS="--single-transaction --skip-lock-tables --flush-logs --hex-blob --master-data=2 -A"
      MYSQLDUMP_OPTIONS="--routines --triggers --single-transaction"
      log "Backup Options: ${MYSQLDUMP_OPTIONS}"

      log "${INSTALL_BIN}/mysqldump ***** ${MYSQLDUMP_OPTIONS} --databases ${DBLIST}"
      ${INSTALL_BIN}/mysqldump ${SOURCE_CONN} ${MYSQLDUMP_OPTIONS} --databases ${DBLIST} > ${BKUP_FILE}

   else 

      #
      # Create Backup File for Replication ...
      #

      log "LogSync Enabled: ${LOGSYNC}"
      if [[ "${LOGSYNC}" == "true" ]]
      then 
         log "Backup CMD: ${INSTALL_BIN}/mysqldump ${SOURCE_CONN} --all-databases --skip-lock-tables --single-transaction --flush-logs --hex-blob --master-data=2 -A"
         ##log "Backup CMD: ${INSTALL_BIN}/mysqldump ******** --all-databases --skip-lock-tables --single-transaction --flush-logs --hex-blob --master-data=2 -A > ${BKUP_FILE}"
         ${INSTALL_BIN}/mysqldump ${SOURCE_CONN} --all-databases --skip-lock-tables --single-transaction --flush-logs --hex-blob --master-data=2 -A  > ${BKUP_FILE}
      else 
         log "Backup CMD: ${INSTALL_BIN}/mysqldump ${SOURCE_CONN} --all-databases --skip-lock-tables --single-transaction --flush-logs --hex-blob"
         ##log "Backup CMD: ${INSTALL_BIN}/mysqldump ******** --all-databases --skip-lock-tables --single-transaction --flush-logs --hex-blob > ${BKUP_FILE}"
         ${INSTALL_BIN}/mysqldump ${SOURCE_CONN} --all-databases --skip-lock-tables --single-transaction --flush-logs --hex-blob > ${BKUP_FILE}
      fi 

   fi

   #
   # Verify Backup File Exists ...
   #
   FS=`du -s ${BKUP_FILE} 2>/dev/null`
   FS=`echo ${FS} | ${AWK} -F " " '{print $1}' | xargs`
   log "Backup File Size: ${FS}"
   if [[ "${FS}" == "" ]] || [[ "${FS}" == "0" ]]
   then
      die "ERROR: Backup File ${BKUP_FILE} Not Created, or is Empty ${FS} ..."
   fi

   STAT=`ls -ll ${BKUP_FILE}`
   log "Backup File: ${STAT}"
   echo "Delphix Backup File: ${STAT}"

else	# else if ${BACKUP_PATH} ...


   #
   # Customer Provided Backup File ...
   #
   log "Skipping Backup, File Provided ... "
   if [[ -f ${BACKUP_PATH} ]] 
   then
      FS=`du -s ${BACKUP_PATH} 2>/dev/null`
      FS=`echo ${FS} | ${AWK} -F " " '{print $1}' | xargs`
      log "Provided Backup File Size: ${FS}"
      if [[ "${FS}" == "" ]] || [[ "${FS}" == "0" ]]
      then
         die "ERROR: Provided Backup File ${BACKUP_PATH} Not Created, or is Empty ${FS} ..."
      fi
      STAT=`ls -ll ${BACKUP_PATH}`
      log "Customer Backup File: ${STAT}"
      echo "Customer Backup File: ${STAT}"
   else 
      die "ERROR: Provided Backup File ${BACKUP_PATH} does not exist ..."
   fi
fi       #  end if ${BACKUP_PATH} ...

log "Environment: "
export DLPX_LIBRARY_SOURCE=""
export REPLICATION_PASS=""
export STAGINGPASS=""
env | sort  >>$DEBUG_LOG
log "-- End --"
exit 0
