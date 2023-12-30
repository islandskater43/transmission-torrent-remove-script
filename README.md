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
3. Run a test run
```
sh transmission-delete-files.sh
```
4. Configure in crontab
```
crontab -e
```
Add the following to trigger the script every day at 7 am.
```
0 7 * * * /path/to/transmission-delete-files.sh
```

## Additional References
* AWS SES send-email documentation - https://docs.aws.amazon.com/cli/latest/reference/ses/send-email.html
* Downloading AWS CLI V2 on a Raspberry Pi - https://luther.io/articles/aws-cli-on-rpi/