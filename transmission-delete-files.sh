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

CUTOFF=`expr 86400 \* $TIMETOKEEP`
LOGPREFIX="transmission-delete-files.sh -"
DELETEMODE=false
DELETEBYTES=0

logger "$LOGPREFIX Start of Run"
if $DRYRUN; then
    logger "$LOGPREFIX Dry Run Active - No files will be deleted!"
fi

## Determine if we need to free up space
MINIMUM_FREE_SPACE=`expr ${MINIMUM_FREE_SPACE_GB} \* 1048576`
AVAILABLE_SPACE=$(df $TARGET | sed -n '2p' | awk '{print $4}')
AVAILABLE_SPACE_GB=`expr ${AVAILABLE_SPACE} / 1048576`

## Log current space details
logger "$LOGPREFIX Drive Space available: ${AVAILABLE_SPACE_GB} GB"
logger "$LOGPREFIX Minimum Space Req'd:   ${MINIMUM_FREE_SPACE_GB} GB"

if [ $MINIMUM_FREE_SPACE -gt $AVAILABLE_SPACE ]; then
    logger "$LOGPREFIX Running out of space - Delete Mode activated!"
    DELETEBYTES=`expr $MINIMUM_FREE_SPACE - $AVAILABLE_SPACE`
    logger "$LOGPREFIX Need to delete: $DELETEBYTES bytes"
    DELETEMODE=true
fi

# Tokenise over newlines instead of spaces.
OLDIFS=$IFS
IFS="
"

for ENTRY in `$BIN -n $USER:$PASS -l | grep 100%.*Done`; do
    # Pull the ID out of the listing.
    ID=`echo $ENTRY | sed "s/^ *//g" | sed "s/ *100%.*//g"`

    THISFILESIZE=0

    # Determine the name of the downloaded file/folder.
    NAME=`$BIN -n $USER:$PASS -t $ID -f | head -1 |\
         sed "s/ ([0-9]\+ files)://g"`

    # If it's a folder, find the last modified file and its modification time.
    if [ -d "$TARGET/$NAME" ]; then
        LASTMODIFIED=0
        for FILE in `find $TARGET -name $NAME`; do
             AGE=`stat "$FILE" -c%Y`
             if [ $AGE -gt $LASTMODIFIED ]; then
                 LASTMODIFIED=$AGE
             fi
        done

    # Otherwise, just get the modified time.
    else
	    FILE1=`find $TARGET -name $NAME`
        LASTMODIFIED=`stat "$FILE1" -c%Y`    
    fi

    TIME=`date +%s`
    DIFF=`expr $TIME - $LASTMODIFIED`

    # Remove the torrent if it's older than the CUTOFF.
    if [ $DIFF -gt $CUTOFF ]; then
        if [ ! $DRYRUN -a $DELETEMODE ]; then
            logger "$LOGPREFIX Removing $NAME with ID:$ID"
            aws --region us-east-1 ses send-email --from $FROMEMAIL --to $TOEMAIL --subject "Torrent Deleted" --text "The following torrent was deleted: $NAME"
            $BIN -n $USER:$PASS -t $ID --remove-and-delete
        else
            logger "$LOGPREFIX Won't remove $NAME with ID:$ID, despite being too old due to dry run or delete mode"
        fi
    fi

done

IFS=$OLDIFS

logger "$LOGPREFIX End of Run"