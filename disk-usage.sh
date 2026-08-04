#!/bin/bash

DISK_USAGE=$(df -HT | awk 'NR>1 {gsub("%","",$6); print $7,$6}')
DISK_THRESHOLD=1

MSG=""

while IFS= read -r line
do
    DISK_PATH=$(echo "$line" | awk '{print $1}')
    DISK_USAGE_PERCENT=$(echo "$line" | awk '{print $2}')

    if [ "$DISK_USAGE_PERCENT" -gt "$DISK_THRESHOLD" ]
    then
        MSG+="Warning: $DISK_PATH is using $DISK_USAGE_PERCENT of its space."
    fi
done <<< "$DISK_USAGE"

echo -e "$MSG"