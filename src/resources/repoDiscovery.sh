#
# Copyright (c) 2018 by Delphix. All rights reserved.
#
# Repository discovery for MySQL by searching for mysqld files ...
#

##DEBUG## In Delphix debug.log
#set -x

#
# Program Name ...
#
PGM_NAME="repoDiscovery.sh"		# used in log and errorLog

#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
result=`hey`
log "------------------------- Start"
log "Library Loaded ... hey $result"
WHO=`whoami`
log "whoami: ${WHO}"

#
# Binaries used to find directory name basename and awk
#
DNAME=`which dirname`
BNAME=`which basename`
AWK=`which awk`

#
# Create empty JSON output array ...
#
repoList='[]'

#
# Find the list of mysqld file(s) excluding /etc ...
# This gives the list of directories ike this
#/opt/mysql57/mysql-5.7.10-linux-glibc2.5-x86_64_e/bin/mysqld
#/opt/mysql57/mysql-5.7.9-linux-glibc2.5-x86_64_d/bin/mysqld
#/opt/mysql55/mysql-5.5.38-linux2.6-x86_64/bin/mysqld
#/opt/mysql56/mysql-5.6.25-linux-glibc2.5-x86_64_c/bin/mysqld

FILES=`find / -not \( -path /etc -prune \) -name mysqld -type f -print 2>&1 | grep -v 'Permission denied'`
log "mysqld files: ${FILES}"



OLD_IFS="$IFS"
IFS=$'\n'
for F1 in ${FILES}; do

   PATH=`${DNAME} "${F1}"`
   
   BASENAME=`${BNAME} "${F1}"`

   STR=`${F1} --version`
   # Result is /opt/mysql56/mysql-5.6.25-linux-glibc2.5-x86_64_c/bin/mysqld  Ver 5.6.25 for Linux on x86_64 (MySQL Community Server (GPL))

   log "Processing Executable: |$STR|"

   VER=`echo "${STR}" | ${AWK} -F" " '{ print $3 }'`.  # value-  5.6.25
 
   PRETTY=`echo "${STR}" | ${AWK} -F" " '{ print substr($i,index($0,$8)) }'`. # Value - (MySQL Community Server (GPL))

   #echo "$F1  ... $PATH ... $STR ... $VER ... $PRETTY "

   #
   # Output ...
   #  - skip mysqld-safe commands
   #  - skip any mysqld files that don't generate a version
   #
   if [[ ! "${PATH}" = *"mysql-safe"* ]] && [[ "${VER}" != "" ]] && [[ "${BASENAME}" == "mysqld" ]] 
   then
      repo='{}'
      repo=$($DLPX_BIN_JQ ".installPath = $(jqQuote "$PATH")" <<< "$repo")

      # repo looke like this
      #{ "installPath": "/opt/mysql56/mysql-5.6.25-linux-glibc2.5-x86_64_c/bin/mysqld" }

      repo=$($DLPX_BIN_JQ ".version = $(jqQuote "$VER")" <<< "$repo")
      repo=$($DLPX_BIN_JQ ".prettyName = $(jqQuote "$PATH $PRETTY $VER")" <<< "$repo")
      repoList=$($DLPX_BIN_JQ ". + [$repo]" <<< "$repoList")
   fi

done
IFS="$OLD_IFS"

log "Output: $repoList"
#echo "$repoList" > "$DLPX_OUTPUT_FILE"
echo "$repoList"

#log "Environment: "
#export DLPX_LIBRARY_SOURCE=""
#env | sort  >>$DEBUG_LOG
log "---Ending ---"
exit 0
