#!/bin/sh

# Automatically remove a torrent and delete its data after a specified period of
# time (in seconds).

## Folder where torrents are stored
TARGET=/path/to/torrents

## RPC User / Pass auth creds for transmission
USER=
PASS=

## Path to transmission remote
BIN="/usr/bin/transmission-remote"

## Number of days to keep torrents 
TIMETOKEEP=60

## Minimum Drive Free Space (in GB)
MINIMUM_FREE_SPACE_GB=150

## Email Notification
FROMEMAIL=
TOEMAIL=

## Debugging
DRYRUN=true

##############################################
### You shouldn't need to edit below here. ###
##############################################

CUTOFF=$(expr 86400 \* $TIMETOKEEP)
LOGPREFIX="transmission-delete-files.sh -"
DELETEBYTES=0

logger "$LOGPREFIX Start of Run"
if $DRYRUN; then
    logger "$LOGPREFIX Dry Run Active - No files will be deleted!"
fi

## Determine if we need to free up space
MINIMUM_FREE_SPACE=$(expr ${MINIMUM_FREE_SPACE_GB} \* 1073741824)
AVAILABLE_SPACE=$(df $TARGET | sed -n '2p' | awk '{print $4}')
## df outputs in kb, so multiple AVAILABLE_SPACE by 1024
AVAILABLE_SPACE=$(expr $AVAILABLE_SPACE \* 1024)
AVAILABLE_SPACE_GB=$(expr ${AVAILABLE_SPACE} / 1073741824)

## Log current space details
logger "$LOGPREFIX Drive Space available: ${AVAILABLE_SPACE_GB} GB"
logger "$LOGPREFIX Minimum Space Req'd:   ${MINIMUM_FREE_SPACE_GB} GB"
logger "$LOGPREFIX Minimum Space Req'd:   ${MINIMUM_FREE_SPACE}"

if [ $MINIMUM_FREE_SPACE -gt $AVAILABLE_SPACE ]; then
    DELETEBYTES=$(expr $MINIMUM_FREE_SPACE - $AVAILABLE_SPACE)
    logger "$LOGPREFIX Running out of space - Need to delete: $DELETEBYTES bytes - Delete Mode activated!"
else
    logger "$LOGPREFIX Exiting as no files need to be deleted."
    exit 0
fi

# Tokenise over newlines instead of spaces.
OLDIFS=$IFS
IFS="
"

for ENTRY in $($BIN -n $USER:$PASS -l | grep 100%.*Done); do
    # Pull the ID out of the listing.
    ID=$(echo $ENTRY | sed "s/^ *//g" | sed "s/ *100%.*//g")

    THISFILESIZE=0

    # Determine the name of the downloaded file/folder.
    NAME=$($BIN -n $USER:$PASS -t $ID -f | head -1 | sed "s/ ([0-9]\+ files)://g")

    # Find the file -- might be in a subdirectory
    FILE1=$(find $TARGET -name $NAME)
    LASTMODIFIED=$(stat "$FILE1" -c%Y)

    # If it's a folder, find the last modified file and its modification time.
    if [ -d $FILE1 ]; then
        THISFILESIZE=$(du -sb "$FILE1" | awk '{print $1;}')
        logger "$LOGPREFIX $NAME is a directory, modified on $LASTMODIFIED; path is $FILE1; filesize = $THISFILESIZE"
    # Otherwise, just get the modified time.
    else
        THISFILESIZE=$(stat "$FILE1" -c%s)
        logger "$LOGPREFIX $NAME is a file, modified on $LASTMODIFIED; file is $FILE1; filesize = $THISFILESIZE"
    fi

    TIME=$(date +%s)
    DIFF=$(expr $TIME - $LASTMODIFIED)

    # Remove the torrent if it's older than the CUTOFF.
    if [ $DIFF -gt $CUTOFF ]; then
        if [ "$DRYRUN" = false ]; then
            logger "$LOGPREFIX Removing $NAME with ID:$ID"
            aws --region us-east-1 ses send-email --from $FROMEMAIL --to $TOEMAIL --subject "Torrent Deleted" --text "The following torrent was deleted: $NAME"
            $BIN -n $USER:$PASS -t $ID --remove-and-delete
        else
            logger "$LOGPREFIX Won't remove $NAME with ID:$ID, despite being too old due to dry run or delete mode"
        fi
        TOTALDELETED=$(expr $TOTALDELETED + $THISFILESIZE)
    fi

    # once we've deleted enough, break out
    if [ $TOTALDELETED -gt $DELETEBYTES ]; then
        logger "$LOGPREFIX Deleted sufficient files. Exiting loop."
        break
    fi

done

IFS=$OLDIFS

logger "$LOGPREFIX End of Run"