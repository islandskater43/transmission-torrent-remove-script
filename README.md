# transmission-torrent-remove-script
Script to remove torrents after a period of time. Originally based off of [this example](https://forum.transmissionbt.com/viewtopic.php?t=13427) in the Transmission Forum.

## Requirements
* Requires the AWS CLI V2 to be installed and configured for email notification of deleted torrents

## Setup
1. Download the script
```
wget https://raw.githubusercontent.com/islandskater43/transmission-torrent-remove-script/main/transmission-delete-files.sh
```
2. Configure the variables in the script for your system
3. Make the script executable
```
chmod u+x transmission-delete-files.sh
```
4. Run a test run
```
sh transmission-delete-files.sh
```
5. If all looks good, change the `DRYRUN` flag to `false` to enable the script to call transmission to remove-and-delete.
6. Configure in crontab
```
crontab -e
```
Add the following to trigger the script to run hourly - customize as you see fit. 
```
0 * * * * /path/to/transmission-delete-files.sh
```

## Additional Resources
* AWS SES send-email documentation - https://docs.aws.amazon.com/cli/latest/reference/ses/send-email.html
* Downloading AWS CLI V2 on a Raspberry Pi - https://luther.io/articles/aws-cli-on-rpi/
