#
# Copyright (c) 2018 by Delphix. All rights reserved.
#
# This file handles sourceConfig discovery for Mongo. 
# It will only scan for running instances of Mongod and will NOT find dormant instances
#

##DEBUG## In Delphix debug.log
#set -x

#
# Program Name ...
#
PGM_NAME="sourceConfigDiscovery.sh"    		# used in log and errorLog

#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
result=`hey`
log "------------------------- Start"
log "Library Loaded ... hey $result"

#
# create empty output list
#
sourceConfigList='[]'

#
# get the list of install paths
#
##DEBUG## INSTALLPATH="/usr/local/mysql/bin/mysqld"
log "INSTALLPATH: ${INSTALLPATH}"
BINPATH=`dirname $INSTALLPATH`
BASEPATH=`dirname $BINPATH`
instances=$(ps -ef | grep "$BINPATH/mysql[d] ")

#
# for each install path, get the version and add the repo object
#
OLD_IFS="$IFS"
IFS=$'\n'
for instance in $instances; do
   #port=$("$INSTALLPATH" get-port "$instance")
   #dataPath=$("$INSTALLPATH" get-data-path "$instance")
#   port=`echo ${instance} | awk -F" " '{ print $3 }'`
#   dataPath=`cut -d" " -f 5 <<< "${instance}"`
#   version=`cut -d"/" -f 5 <<< "${instance}"`

   str=`echo $instance | awk '{ s = ""; for (i = 8; i <= NF; i++) s = s $i " "; print s }'`  
   datadir=`echo "$str" | awk 'BEGIN {RS=" "}; /--datadir/' | cut -d"=" -f2`
   port=`echo "$str" | awk 'BEGIN {RS=" "}; /--port/' | cut -d"=" -f2`
   log "--datadir=${datadir}"
   log "--port=${port}"
   version="5.#"

   dbName="${instance##*/}"
   prettyName="MySQL_DB - $port $datadir"
   sourceConfig='{}'
   sourceConfig=$($DLPX_BIN_JQ ".dbName = $(jqQuote "$dbName")" <<< "$sourceConfig")
   sourceConfig=$($DLPX_BIN_JQ ".dataPath = $(jqQuote "$datadir")" <<< "$sourceConfig")
   sourceConfig=$($DLPX_BIN_JQ ".version = $(jqQuote "$version")" <<< "$sourceConfig")
   sourceConfig=$($DLPX_BIN_JQ ".prettyName = $(jqQuote "$prettyName")" <<< "$sourceConfig")
   sourceConfig=$($DLPX_BIN_JQ ".port = $(jqQuote "$port")" <<< "$sourceConfig")
   sourceConfigList=$($DLPX_BIN_JQ ". + [$sourceConfig]" <<< "$sourceConfigList")
done
IFS="$OLD_IFS"

log "Output: ${sourceConfigList}"
echo "$sourceConfigList" > "$DLPX_OUTPUT_FILE"

#log "Environment: "
#export DLPX_LIBRARY_SOURCE=""
#env | sort  >>$DEBUG_LOG
log "------------------------- End"
exit 0
