#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# library.sh
#
# Library of common MySQL toolkit functions ... 
#

###########################################################
## Required Environment Variables ...

#
# Delphix Supplied Environment Variables ...
# 
# DLPX_BIN_JQ=`which jq`
# DLPX_DATA_DIRECTORY
# 
# Additional Data Specific ...
#
# ? DLPX_TMP_DIRECTORY
#
# Toolkit Specific ...
# 
DLPX_TOOLKIT_NAME="mysql" 
#${DLPX_BIN}="/var/opt/delphix/toolkit/Delphix_COMMON_564d1a3e_4dee_b451_14d5_9bfc5ccf1dc5_delphix_host/scripts/bin"
dlpx_db_exec_script="$DLPX_BIN/dlpx_db_exec"
DLPX_TOOLKIT=$( dirname "${DLPX_BIN}" )
DLPX_TOOLKIT=$( dirname "${DLPX_TOOLKIT}" )
DLPX_TOOLKIT=$( dirname "${DLPX_TOOLKIT}" )
DLPX_LOG_DIRECTORY="${DLPX_TOOLKIT}" 	#"/tmp"     # ="${DLPX_DATA_DIRECTORY}/.."
                                        # or hidden home dir, /home/delphix/.delphix ???

###########################################################
## Globals

TOOLKIT_VERSION="0.9.2"
TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S)
CONFIG_OUTPUT_FILE="delphix_${DLPX_TOOLKIT_NAME}_config.dat"
ERROR_LOG=${DLPX_LOG_DIRECTORY}/"delphix_${DLPX_TOOLKIT_NAME}_error.log"
DEBUG_LOG=${DLPX_LOG_DIRECTORY}/"delphix_${DLPX_TOOLKIT_NAME}_debug.log"
INFO_LOG=${DLPX_LOG_DIRECTORY}/"delphix_${DLPX_TOOLKIT_NAME}_info.log"

AWK=`which awk`
DIRNAME=`which dirname`
BASENAME=`which basename`
XARGS=`which xargs`

###########################################################
## Functions ...

function printParams {
   log "==== PRINT PARAMS ====="
   log "dlpx_db_exec_script >> ${dlpx_db_exec_script}"
   log "DLPX_BIN >> ${DLPX_BIN}"
   log "DLPX_TOOLKIT >> ${DLPX_TOOLKIT}"
   log "DEBUG_LOG >> ${DEBUG_LOG}"
   log "CONFIG_OUTPUT_FILE >> ${CONFIG_OUTPUT_FILE}"
   log "DLPX_LOG_DIRECTORY >> ${DLPX_LOG_DIRECTORY}"
   log "==== PRINT PARAMS ====="
}

# Log infomation and die if option -d is used.
function log {
   Parms=$@
   die='no'
   if [[ $1 = '-d' ]]; then
      shift
      die='yes'
      Parms=$@
   fi
   ##printf "[${DLPX_GUID}][${TIMESTAMP}][DEBUG][%s][%s]:[$Parms]\n" $DLPX_TOOLKIT_WORKFLOW $PGM_NAME >>$DEBUG_LOG
   printf "[${TIMESTAMP}][DEBUG][%s][%s]:[$Parms]\n" $DLPX_TOOLKIT_WORKFLOW $PGM_NAME >>$DEBUG_LOG
   if [[ $die = 'yes' ]]; then
      exit 2
   fi
}

# Log infomation and die if option -d is used.
function infolog {
   Parms=$@
   die='no'
   if [[ $1 = '-d' ]]; then
      shift
      die='yes'
      Parms=$@
   fi
   printf "[${TIMESTAMP}][INFO][%s][%s]:[$Parms]\n" $DLPX_TOOLKIT_WORKFLOW $PGM_NAME >>$INFO_LOG
   if [[ $die = 'yes' ]]; then
      exit 2
   fi
}

#
# Log error and write to the errorlog
#
function errorLog {
   log "$@"
   echo -e "[${TIMESTAMP}][ERROR][$@]" >>$ERROR_LOG
}

#
# Write to log and errorlog before exiting with an error code
#
function die {
   log "die"
   errorLog "$@"
   exit 2
}

#
# Function to check for errors and die with passed in error message
#
function errorCheck {
   if [ $? -ne 0 ]; then
      die "$@"
   fi
}

#
# Function to collect system info
# ARCH, OSTYPE, OSVERSION
#
function getSystemInfo {
   ARCH=$(uname -p)
   OSTYPE=$(uname)
   if [ "$OSTYPE" = "SunOS" ]; then
      OSTYPE="Solaris"
      OSVERSION=$(uname -v)
      OSSTR="$OSTYPE ${REV}(${ARCH} `uname -v`)"
   elif [ "$OSTYPE" = "AIX" ]; then
      OSSTR="$OSTYPE `oslevel` (`oslevel -r`)"
      OSVERSION=$(oslevel)
   elif [ "$OSTYPE" = "Linux" ]; then
      if [ -f /etc/redhat-release ]; then
         OSTYPE=RedHat
         OSVERSION=$(cat /etc/redhat-release | sed 's/.*release\ //' | sed 's/\ .*//')
      else
         #die "Unsupported Linux Distro"
         OSTYPE=Unknown
         OSVERSION=Unsupported
     fi
   else 
      OSVERSION=Unsupported
   fi
}

#
# Quotes strings for use with JSON. Fails if the number of arguments is not
# exactly one because it will not do what the user likely expects.
#
function jqQuote {
   if [[ "$#" -ne 1 ]]; then
      log -d "Wrong number of arguments to jqQuote: $@"
   fi
   $DLPX_BIN_JQ -R '.' <<< "$1"
}

function purgeLogs {
   MaxFileSize=20971520
   DT=`date '+%Y%m%d%H%M%S'`
   log "Checking Log File Sizes ... "
   #
   # Debug Log
   #
   file_size=`du -b ${DEBUG_LOG} | tr -s '\t' ' ' | cut -d' ' -f1`
   if [ $file_size -gt $MaxFileSize ];then
      mv ${DEBUG_LOG} ${DEBUG_LOG}_${DT}
      touch ${DEBUG_LOG}
   fi
   #
   # Error Log
   #
   file_size=`du -b ${ERROR_LOG} | tr -s '\t' ' ' | cut -d' ' -f1`
   if [ $file_size -gt $MaxFileSize ];then
      mv ${ERROR_LOG} ${ERROR_LOG}_${DT}
      touch ${ERROR_LOG}
   fi
}

#
# Get Port, DataDir, BaseDir and Status Info ...
#
# Usage:
#   RESULTS=$( portStatus "${PORT}" )
#   echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".status"
#
portStatus () {

   ZPORT=${1}

   if [[ "${ZPORT}" == "" ]]
   then
      errorLog "ERROR: Missing port ${ZPORT}, exiting ..."
      exit 1
   fi
   log "Check Status for Port ${ZPORT} ..."

   #
   # Check if Port is included in the process command ...
   #
   ZPSEF=`ps -ef | grep -E "[m]ysqld .*--port=${ZPORT}" | grep -v grep`
   log "Process Status: ${ZPSEF}"

   ZPSID=`echo "${ZPSEF}" | ${AWK} -F" " '{print $2}'`
   ZPSCMD=`echo "${ZPSEF}" | ${AWK} -F" " '{print $8}'`

   if [[ "${ZPSID}" == "" ]]
   then
      ZPSEF=`ps -ef | grep -E "[m]ysqld .*-p.*${ZPORT}" | grep -v grep`
      log "Short Option Process Status: ${ZPSEF}"
      PSID=`echo "${ZPSEF}" | ${AWK} -F" " '{print $2}'`
      PSCMD=`echo "${ZPSEF}" | ${AWK} -F" " '{print $8}'`
   fi

   log "PSID: ${ZPSID}"
   log "PSCMD: ${ZPSCMD}"

   ZPORT_CHK=""
   ZSOCKET=""
   ZBASEDIR=""
   ZDATADIR=""

   # Process Exist, get data values from process ...
   if [[ "${ZPSID}" != "" ]]
   then
      zstr=`echo "$ZPSEF" | ${AWK} '{ s = ""; for (i = 8; i <= NF; i++) s = s $i " "; print s }'`
      log "$zstr"
      ZPGCMD=`echo $zstr | ${AWK} -F" " '{print $1}' | xargs`
      ZPGBIN=`dirname "${ZPGCMD}"`

      ZPORT_CHK=`echo "${ZPSEF}" | ${AWK} 'BEGIN {RS=" "}; /--port/' | cut -d"=" -f2 | tr '\n' ' ' | xargs`
      log "--port check: ${ZPORT_CHK}"

      ZSOCKET=`echo "${ZPSEF}" | ${AWK} 'BEGIN {RS=" "}; /--socket/' | cut -d"=" -f2 | tr '\n' ' ' | xargs`
      #log "--socket: ${ZSOCKET}"

      ZBASEDIR=`echo "${ZPSEF}" | ${AWK} 'BEGIN {RS=" "}; /--basedir/' | cut -d"=" -f2 | tr '\n' ' ' | xargs`
      #log "--basedir: ${ZBASEDIR}"

      ZDATADIR=`echo "${ZPSEF}" | ${AWK} 'BEGIN {RS=" "}; /--datadir/' | cut -d"=" -f2 | tr '\n' ' ' | xargs`
      #log "--datadir: ${ZDATADIR}"

      ZMYCNF=`echo "${ZPSEF}" | ${AWK} 'BEGIN {RS=" "}; /--defaults-file/' | cut -d"=" -f2 | tr '\n' ' ' | xargs`
      #log "--defaults-file: ${ZMYCNF}"

      ZSERVERID=`echo "${ZPSEF}" | ${AWK} 'BEGIN {RS=" "}; /--server-id/' | cut -d"=" -f2 | tr '\n' ' ' | xargs`
      #log "--server-id: ${ZSERVERID}"

      ZPIDFILE=`echo "${ZPSEF}" | ${AWK} 'BEGIN {RS=" "}; /--pid-file/' | cut -d"=" -f2 | tr '\n' ' ' | xargs`
      #log "--pid: ${ZPIDFILE}"

      ZTMPDIR=`echo "${ZPSEF}" | ${AWK} 'BEGIN {RS=" "}; /--tmpdir/' | cut -d"=" -f2 | tr '\n' ' ' | xargs`
      #log "--tmpdir: ${ZTMPDIR}"
   else
      # If port IS NOT included in the process command, read from my.cnf file if specified ...
      #zinstances=$( ps -ef | grep -E "[m]ysqld .*--defaults-file=" | grep -v grep )
      log "Warning: Missing Process Id for Specified Port ${ZPORT}"
   fi

   # Found valid process ...
   ZSTATUS="INACTIVE"
   if [[ "${ZPSID}" != "" ]] && [[ "${ZPSCMD}" != "" ]] && [[ "${ZDATADIR}" != "" ]]
   then
      ZSTATUS="ACTIVE"
   fi
   echo "{
      \"port\": \"${ZPORT}\",
      \"processId\": \"${ZPSID}\",
      \"processCmd\": \"${ZPSCMD}\",
      \"socket\": \"${ZSOCKET}\",
      \"baseDir\": \"${ZBASEDIR}\",
      \"dataDir\": \"${ZDATADIR}\",
      \"myCnf\": \"${ZMYCNF}\",
      \"serverId\": \"${ZSERVERID}\",
      \"pidFile\": \"${ZPIDFILE}\",
      \"tmpDir\": \"${ZTMPDIR}\",
      \"status\": \"${ZSTATUS}\"
    }"
}

#
# Stop Database ...
# Usage:
#  stopDatabase "${RESULTS_JSON}" "${SOURCE_CONN}"
#
stopDatabase() {
   ZRESULTS=${1}
   ZCONN=${2}
   ZOPTIONS=${3}

   log "Stop JSON: ${ZRESULTS}"

   ZPORT=`echo "${ZRESULTS}" | $DLPX_BIN_JQ --raw-output ".port"`
   ZPSID=`echo "${ZRESULTS}" | $DLPX_BIN_JQ --raw-output ".processId"`
   ZPSCMD=`echo "${ZRESULTS}" | $DLPX_BIN_JQ --raw-output ".processCmd"`
   ZDATADIR=`echo "${ZRESULTS}" | $DLPX_BIN_JQ --raw-output ".dataDir"`
   ZBASEDIR=`echo "${ZRESULTS}" | $DLPX_BIN_JQ --raw-output ".baseDir"`
   ZLOGSYNC=`echo "${ZRESULTS}" | $DLPX_BIN_JQ --raw-output ".logSync"`

   echo "ZCONN:"
   echo "$ZCONN"

   # Found valid process ...
   if [[ "${ZPORT}" != "" ]] && [[ "${ZPSID}" != "" ]]
   then
      if [[ -f "${ZBASEDIR}/bin/mysqladmin" ]] && [[ "${ZPORT}" != "" ]]
      then
         if [[ "${ZLOGSYNC}" == "true" ]]
         then
            masklog "Shutdown Slave: ${ZBASEDIR}/bin/mysqladmin ${ZCONN} stop-slave"
            CMD="${ZBASEDIR}/bin/mysqladmin ${ZCONN} stop-slave"
            ##eval ${CMD} </dev/null >/dev/null 2>&1 & disown "$!"
            eval ${CMD} 1>>${DEBUG_LOG} 2>&1
         fi
         # Shutdown Database ...
         masklog "Shutdown: ${ZBASEDIR}/bin/mysqladmin ${ZCONN} shutdown"
         CMD="${ZBASEDIR}/bin/mysqladmin ${ZCONN} shutdown" 
         log "Executing shutdown"
         #eval ${CMD} </dev/null >/dev/null 2>&1 & disown "$!"
         eval ${CMD} 1>>${DEBUG_LOG} 2>&1
         sleep 4

      else
         log "Warning: Invalid Path or Missing File to ${ZBASEDIR}/bin/mysqladmin ..."
      fi 

      ZPSEF2=$( ps -ef | grep -E "[m]ysqld .*--port=${ZPORT}" )
      ZPSID2=`echo "${ZPSEF2}" | ${AWK} -F" " '{print $2}'`
      if [[ "${ZPSID}" == "${ZPSID2}" ]]
      then
        log "Killing ${ZPSID}"
        kill -9 ${ZPSID}
        sleep 10
      fi

      # Verify ...
      ZPSEF2=$( ps -ef | grep -E "[m]ysqld .*--port=${ZPORT}" )
      ZPSID2=`echo "${ZPSEF2}" | ${AWK} -F" " '{print $2}'`
      if [[ "${ZPSID2}" == "" ]]
      then
         log "Database Shutdown Confirmed ..."
      else
         log "Warning: Unknown Database Status ..."
      fi
   else
      log "Warning: Shutdown aborted since port/process id does not exist or was not specified ..."
   fi 
   # return status?
}  

#
# Start Database ...
#
# Usage:
# startDatabase "${JSON}" "${SOURCE_CONN}"
#
startDatabase() {
   ZRESULTS="${1}"
   ZCONN="${2}"
   ZOPTIONS="${3}"
   ZSTARTSLAVE="${4}"
   log "ZSTARTSLAVE is: '${ZSTARTSLAVE}'"

   log "Startup JSON: ${ZRESULTS}"
   ZPORT=`echo "${ZRESULTS}" | $DLPX_BIN_JQ --raw-output ".port"`
   ZSOCKET=`echo "${ZRESULTS}" | $DLPX_BIN_JQ --raw-output ".socket"`
   ZPSID=`echo "${ZRESULTS}" | $DLPX_BIN_JQ --raw-output ".processId"`
   ZPSCMD=`echo "${ZRESULTS}" | $DLPX_BIN_JQ --raw-output ".processCmd"`
   ZDATADIR=`echo "${ZRESULTS}" | $DLPX_BIN_JQ --raw-output ".dataDir"`
   ZBASEDIR=`echo "${ZRESULTS}" | $DLPX_BIN_JQ --raw-output ".baseDir"`
   ZMYCNF=`echo "${ZRESULTS}" | $DLPX_BIN_JQ --raw-output ".myCnf"`
   ZSERVERID=`echo "${ZRESULTS}" | $DLPX_BIN_JQ --raw-output ".serverId"`
   ZPIDFILE=`echo "${ZRESULTS}" | $DLPX_BIN_JQ --raw-output ".pidFile"`
   ZTMPDIR=`echo "${ZRESULTS}" | $DLPX_BIN_JQ --raw-output ".tmpDir"`
   ZLOGSYNC=`echo "${ZRESULTS}" | $DLPX_BIN_JQ --raw-output ".logSync"`
   ZSTATUS=`echo "${ZRESULTS}" | $DLPX_BIN_JQ --raw-output ".status"`

   ZCMD="${ZPSCMD}/mysqld"
   ZTMP=$(${BASENAME} ${ZPSCMD})
   if [[ "${ZTMP}" == "mysqld_safe" ]]
   then
      ZCMD="${ZPSCMD}"
   fi
   # Start Database ...
   if [[ "${ZSTATUS}" != "ACTIVE" ]] 
   then 

      ZMOUNTDIR=`${DIRNAME} ${ZDATADIR}`
      CMD="${ZCMD} ${ZOPTIONS} --defaults-file=${ZMYCNF} --basedir=${ZBASEDIR} --datadir=${ZDATADIR} --pid-file=${ZPIDFILE} --port=${ZPORT} --server-id=${ZSERVERID} --socket=${ZSOCKET} --tmpdir=${ZTMPDIR}"
      masklog "Startup Command: ${CMD} "

      # Shoutout to Tom Walsh for the independent shell params !!!
      ${CMD} </dev/null >/dev/null 2>&1 & disown "$!"

      masklog "Waiting before checking status: ${CMD} "
      sleep 10

      ZPSEF=$( ps -ef | grep -E "[m]ysqld .*--port=${ZPORT}" )
      log "Running process Status: ${ZPSEF}"

      ZPSID=`echo "${ZPSEF}" | ${AWK} -F" " '{print $2}'`
      log "Database Started on ProcessId: ${ZPSID}"

      if [[ -z "$ZPSID" ]]
      then
        log "MySQL Database could not be started."
        terminate "MySQL Database could not be started.No process running." 3
      fi

      INSTALL_BIN="${ZBASEDIR}/bin"
      log "Install bin: ${INSTALL_BIN}"

      # Start Slave 
      log "Starting Slave"
      if [[ "${LOGSYNC}" == "true" && "${ZSTARTSLAVE}" != "NO" ]]
      then
         masklog "ZCONN value for: ${ZCONN}"
         CMD="${INSTALL_BIN}/mysqladmin ${ZCONN} start-slave"
         masklog "Command to start Slave> ${CMD}"
         eval ${CMD} 1>>${DEBUG_LOG} 2>&1
      fi              # end if $LOGSYNC ...
   else
      log "Warning: MySQL is already running. ABORTING start operation."
   fi
}

#
# Build Connection String ...
#
# Usage:
#   RESULTS=$( buildConnectionString "${CONN}" "${PASS}" "${PORT}" "${IP}" )
#   echo "${RESULTS}" | $DLPX_BIN_JQ --raw-output ".results"
#
buildConnectionString () {
   ZCONN=${1}
   ZPASS=${2}
   ZPORT=${3}
   ZIP=${4}
   # Source Connection for Backup ...
   masklog "Connection Input: ${ZCONN}"
   ZSTRING="${ZCONN} --protocol=TCP --port=${ZPORT}  --host=${ZIP}"  
   if [[ "${ZCONN}" = *" -p"* ]] && [[ "${ZPASS}" != "" ]]
   then
      P1=`echo "${ZCONN}" | ${AWK} -F" -p" '{print $1}' | ${XARGS}`
      P2=`echo "${ZCONN}" | ${AWK} -F" -p" '{print $2}' | ${XARGS}`
      if [[ "${ZCONN}" = *"--host"* ]]
      then
         ZSTRING="${P1} -p${ZPASS} ${P2} --protocol=TCP --port=${ZPORT}"
      else 
         ZSTRING="${P1} -p${ZPASS} ${P2} --protocol=TCP --port=${ZPORT} --host=${ZIP}"
      fi
   fi
   if [[ ! "${ZCONN}" = *"-u"* ]] && [[ "${ZPASS}" != "" ]]
   then
      ZSTRING="-u${ZCONN} -p${ZPASS} --protocol=TCP --port=${ZPORT} --host=${ZIP}"
   fi
   masklog "Updated Connection: ${ZSTRING}"
   echo "{
    \"conn\": \"${ZCONN}\",
    \"pass\": \"${ZPASS}\",
    \"string\": \"${ZSTRING}\"
    }"
}

# Keep for Library Verification
function library_load {
   echo "LOADED"
}

# mask passwords and log into debug
function masklog {
  param=$1
  arr=(${param// / })
  i=0
  for val in "${arr[@]}"
  do
  	if [[ "$val" == --pass* ]]; then
  		arr[i+1]="M******"
  	elif [[ "$val" == -p* ]]; then
  		arr[i]="-p*****"
  	fi
  	let "i=i+1"
  done
  masked="${arr[@]}"
  log $masked
  infolog $masked
}

# Terminate with exit codes
function terminate {
   log "Error Message: $1"
   log "Exit Code: $2"
   errorLog "$1"
   echo "$1" >>/dev/stderr
   exit $2
}


###########################################################
## Test/Debug ...

#set -xv
#log "Log Debug Test ..."
#errorLog "Error Log Debug Test ..."
#getSystemInfo
#log "${ARCH},${OSTYPE},${OSVERSION}"
#json="pretty Name"
#log "JSON: ${json}"
#qjson=`jqQuote "$json"`
#log "JSON: ${qjson}"
#hey
#log "Delphix Bin: ${DLPX_BIN}"
#log "Delphix Toolkit: ${DLPX_TOOLKIT}"

errorLog "Error Log Test"
purgeLogs
