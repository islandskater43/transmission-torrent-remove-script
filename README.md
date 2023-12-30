# transmission-torrent-remove-script
Script to remove torrents after a period of time

## Requirements
* Requires the AWS CLI V2 to be installed and configured for email notification of deleted torrents

## Setup
1. Download the script
```
wget https://raw.githubusercontent.com/islandskater43/transmission-torrent-remove-script/main/transmission-delete-files.sh


```
2. Configure the variables in the script for your system
3. Run a test run
```
sh transmission-delete-files.sh
```
4. Configure in crontab
```
crontab -e
```
Add `* * * * * /path/to/transmission-delete-files.sh`