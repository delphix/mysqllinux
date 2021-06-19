#
# Copyright (c) 2018 by Delphix. All rights reserved.
#

##DEBUG## In Delphix debug.log
#set -x

#
# Program Name ...
#
PGM_NAME='recordVirtual.sh'

#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
result=`library_load`
log "Start ${PGM_NAME}"
log "Library Load Status: $result"

ID=$$
TMP1="${DLPX_DATA_DIRECTORY}/data"
TMP2="/usr/local/mysql"

# create empty output list
repoList='[]'

repo='{}'
#repo=$($DLPX_BIN_JQ ".snapshotID = $(quote "$recId")" <<< "$repo")
repo=$($DLPX_BIN_JQ ".snapshotID = \"$ID\" " <<< "$repo")
repo=$($DLPX_BIN_JQ ".snapHost = \"$HOSTIP\" " <<< "$repo")
repo=$($DLPX_BIN_JQ ".snapPort = \"$PORT\" " <<< "$repo")
repo=$($DLPX_BIN_JQ ".snapDataDir = \"$TMP1\" " <<< "$repo")
repo=$($DLPX_BIN_JQ ".snapBaseDir = \"$TMP2\" " <<< "$repo")
repo=$($DLPX_BIN_JQ ".snapPass = \"$MYROOTPASS\" " <<< "$repo")
repo=$($DLPX_BIN_JQ ".snapBackup = \"\" " <<< "$repo")

echo "$repo" > "$DLPX_OUTPUT_FILE"
#log "Output: $repo"

repo1='{}'
repo1=$($DLPX_BIN_JQ ".snapshotID = \"$ID\" " <<< "$repo1")
repo1=$($DLPX_BIN_JQ ".snapHost = \"$HOSTIP\" " <<< "$repo1")
repo1=$($DLPX_BIN_JQ ".snapPort = \"$PORT\" " <<< "$repo1")
repo1=$($DLPX_BIN_JQ ".snapDataDir = \"$TMP1\" " <<< "$repo1")
repo1=$($DLPX_BIN_JQ ".snapBaseDir = \"$TMP2\" " <<< "$repo1")
repo1=$($DLPX_BIN_JQ ".snapPass = \"*******\" " <<< "$repo1")
repo1=$($DLPX_BIN_JQ ".snapBackup = \"\" " <<< "$repo1")

log "Output: $repo1"


#repoList=$($DLPX_BIN_JQ ". + [$repo]" <<< "$repoList")
#echo "$repoList" > "$DLPX_OUTPUT_FILE"

#log "Environment: "
#export DLPX_LIBRARY_SOURCE=""
#export MYROOTPASS=""
#env | sort  >>$DEBUG_LOG
log "------------------------- End"
exit 0
