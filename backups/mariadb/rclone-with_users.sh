#!/bin/bash

# Project name
PROJECT=[PROJECT NAME]
# Days to rotate the backup
DAYS=[NUM DAYS]
# Server name from rclone
SERVER=[SERVER FROM RCLONE]
# Databases separated by space with double quote for multiple databases
DATABASES=[DATABASES]

localpath=/tmp/$PROJECT/backups
remotepath=$SERVER:/Projetos/$PROJECT/Backups
filename=$PROJECT-$(date +%F).sql
finaldate=$(date +%F --date="-${DAYS} days")

mkdir -p $localpath

echo "Removing old backup files before $finaldate..."
backups=$(rclone lsf $remotepath)

for backup in $backups
do
        actualdate=$(echo $backup | sed -r 's/^[^-]+-([^.]+)\..+$/\1/')
        if [ $(date -d $actualdate +"%Y%m%d") -le $(date -d $finaldate +"%Y%m%d") ]; then
                echo "Deleting remote: $remotepath/$backup"
                rclone delete $remotepath/$backup
        fi
done

echo "Generating a new backup file..."
mysqldump -u backup -pbackup --system=users -B $DATABASES > $localpath/$filename

echo "Compressing SQL file..."
gzip -f $localpath/$filename

echo "Uploading the new backup file.."
rclone copy $localpath/$filename.gz $remotepath