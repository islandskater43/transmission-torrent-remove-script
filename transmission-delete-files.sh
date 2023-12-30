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

## Email Notification
FROMEMAIL=
TOEMAIL=

## Debugging
DRYRUN=true

##############################################
### You shouldn't need to edit below here. ###
##############################################

CUTOFF=`expr 86400 \* $TIMETOKEEP`

# Tokenise over newlines instead of spaces.
OLDIFS=$IFS
IFS="
"

for ENTRY in `$BIN -n $USER:$PASS -l | grep 100%.*Done`; do
    # Pull the ID out of the listing.
    ID=`echo $ENTRY | sed "s/^ *//g" | sed "s/ *100%.*//g"`

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

    # Remove the torrent if its older than the CUTOFF.
    if [ $DIFF -gt $CUTOFF ]; then
        date
        echo "Removing $NAME with ID:$ID"
        if ! $DRYRUN ; then
            echo "delete executed"
            aws --region us-east-1 ses send-email --from $FROMEMAIL --to $TOEMAIL --subject "Torrent Deleted" --text "The following torrent was deleted: $NAME"
            $BIN -n $USER:$PASS -t $ID --remove-and-delete
        fi
    fi

done

IFS=$OLDIFS