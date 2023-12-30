#!/bin/sh

#https://forum.transmissionbt.com/viewtopic.php?t=13427

#https://luther.io/articles/aws-cli-on-rpi/

#https://docs.aws.amazon.com/cli/latest/reference/ses/send-email.html

#@pi:~ $ aws --region us-east-1 ses send-email --from test@email.com --to test@email.com --subject "test" --text "test $NAME email"

# Automatically remove a torrent and delete its data after a specified period of
# time (in seconds).

## Load config values


## Folder where torrents are stored
TARGET=

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

# The default is 10 days (in seconds).


##############################################
### You shouldn't need to edit below here. ###
##############################################

CUTOFF=`expr 86400 \* $TIMETOKEEP`

echo $CUTOFF

exit;

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
#        for FILE in `find $TARGET/$NAME`; do
             AGE=`stat "$FILE" -c%Y`
             if [ $AGE -gt $LASTMODIFIED ]; then
                 LASTMODIFIED=$AGE
             fi
        done

    # Otherwise, just get the modified time.
    else
#        LASTMODIFIED=`stat "$TARGET/$NAME" -c%Y`
	    FILE1=`find $TARGET -name $NAME`
        LASTMODIFIED=`stat "$FILE1" -c%Y`    
    fi

    TIME=`date +%s`
    DIFF=`expr $TIME - $LASTMODIFIED`

    # Remove the torrent if its older than the CUTOFF.
    if [ $DIFF -gt $CUTOFF ]; then
        date
        echo "Removing $NAME with ID:$ID"
        aws --region us-east-1 ses send-email --from $FROMEMAIL --to $TOEMAIL --subject "Torrent Deleted" --text "The following torrent was deleted: $NAME"
        #$BIN -n $USER:$PASS -t $ID --remove-and-delete
    fi

done

IFS=$OLDIFS