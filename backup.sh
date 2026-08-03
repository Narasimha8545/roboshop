#!/bin/bash

START_TIME=$(date +%s)

R="\e[31m"
G="\e[32m"
N="\e[0m"

SOURCE_DIR=$1
DEST_DIR=$2
DAYS=${3:-14}

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename "$0" | cut -d "." -f1)

mkdir -p "$LOGS_FOLDER"

LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

USERID=$(id -u)

check_root() {
    if [ "$USERID" -ne 0 ]; then
        echo -e "${R}Please run the script as root user${N}" | tee -a "$LOG_FILE"
        exit 1
    else
        echo -e "${G}You are running as root user${N}" | tee -a "$LOG_FILE"
    fi
}

validate() {
    if [ "$1" -eq 0 ]; then
        echo -e "${G}$2 ... Successful${N}" | tee -a "$LOG_FILE"
    else
        echo -e "${R}$2 ... Failed${N}" | tee -a "$LOG_FILE"
        exit 1
    fi
}

usage() {
    echo "Usage: sudo sh backup.sh <source_directory> <destination_directory> [days]"
    exit 1
}


# Check root
check_root


# Check arguments
if [ $# -lt 2 ]
then
    usage
fi


# Check source directory
if [ ! -d "$SOURCE_DIR" ]
then
    echo -e "${R}Source directory '$SOURCE_DIR' does not exist${N}" | tee -a "$LOG_FILE"
    exit 1
fi


# Check destination directory
if [ ! -d "$DEST_DIR" ]
then
    echo -e "${R}Destination directory '$DEST_DIR' does not exist${N}" | tee -a "$LOG_FILE"
    exit 1
fi


# Find old log files
FILES=$(find "$SOURCE_DIR" -type f -name "*.log" -mtime +"$DAYS")


if [ -n "$FILES" ]
then
    echo -e "${G}Found log files older than $DAYS days:${N}" | tee -a "$LOG_FILE"
    echo "$FILES" | tee -a "$LOG_FILE"
    TIMESTAMP=$(date +%Y%m%d)
    ZIPFILE="$DEST_DIR/app-logs-$TIMESTAMP.zip"
    echo "$FILES" | zip "$ZIPFILE" -@ &>>"$LOG_FILE"
    validate $? "Creating zip file"
if [ -f "$ZIPFILE" ]
then
    echo -e "${G}Backup completed successfully. Zip file created at: $ZIPFILE${N}" | tee -a "$LOG_FILE"

    while IFS= read -r filepath
    do
        echo -e "${G}Deleting $filepath${N}" | tee -a "$LOG_FILE"
        rm -f "$filepath" &>>"$LOG_FILE"
        validate $? "Deleting $filepath"
    done <<< "$FILES"
    echo -e "${G} more than $DAYS days Old log files deleted successfully.${N}" | tee -a "$LOG_FILE"
else
    echo -e "${R}Backup failed. Zip file not created.${N}" | tee -a "$LOG_FILE"
    exit 1
fi

else

    echo -e "${R}No log files older than $DAYS days found in $SOURCE_DIR${N}" | tee -a "$LOG_FILE"
    exit 1

fi


END_TIME=$(date +%s)

TOTAL_TIME=$((END_TIME - START_TIME))

echo -e "${G}Backup completed successfully in ${TOTAL_TIME} seconds${N}" | tee -a "$LOG_FILE"
