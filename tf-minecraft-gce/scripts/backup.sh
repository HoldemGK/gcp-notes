#!/bin/bash
now=$(date +'%Y%m%d%H%M%S')
screen -r mcs -X stuff '/save-all\n/save-off\n'
gsutil -m cp -R ${BASH_SOURCE%/*}/world gs://${BUCKET_PREFIX}-minecraft-backup/$(date "+%Y%m%d-%H%M%S")-world
screen -r mcs -X stuff '/save-on\n'
echo "saved file at $now"