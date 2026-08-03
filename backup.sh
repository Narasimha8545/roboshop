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

# Check root user
check_root

# Check arguments
if [ $# -lt 2 ]; then
    usage
fi

# Check source directory
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${R}Source directory '$SOURCE_DIR' does not exist${N}" | tee -a "$LOG_FILE"
    exit 1
fi

# Check destination directory
if [ ! -d "$DEST_DIR" ]; then
    echo -e "${R}Destination directory '$DEST_DIR' does not exist${N}" | tee -a "$LOG_FILE"
    exit 1
fi


# Find old log files
FILES=$(find "$SOURCE_DIR" -type f -name "*.log" -mtime +$DAYS)


if [ -n "$FILES" ]
then

    echo -e "${G}Found log files older than $DAYS days:${N}" | tee -a "$LOG_FILE"
    echo "$FILES" | tee -a "$LOG_FILE"


    TIMESTAMP=$(date +%Y%m%d)
    ZIPFILE="$DEST_DIR/app-logs-$TIMESTAMP.zip"


    # Check duplicate backup
    if [ -f "$ZIPFILE" ]
    then
        echo -e "${G}Backup already exists: $ZIPFILE${N}" | tee -a "$LOG_FILE"
        exit 0
    fi


    # Create zip file
    echo "Creating zip file $ZIPFILE ..." | tee -a "$LOG_FILE"

    echo "$FILES" | zip "$ZIPFILE" -@ &>>"$LOG_FILE"

    validate $? "Creating zip file"


    # Verify zip contents
    echo "Checking zip contents..." | tee -a "$LOG_FILE"

    unzip -t "$ZIPFILE" &>>"$LOG_FILE"

    validate $? "Listing contents of zip file"


else

    echo -e "${R}No log files older than $DAYS days found in $SOURCE_DIR${N}" | tee -a "$LOG_FILE"
    exit 1

fi


END_TIME=$(date +%s)

TOTAL_TIME=$((END_TIME - START_TIME))

echo -e "${G}Backup completed successfully in ${TOTAL_TIME} seconds${N}" | tee -a "$LOG_FILE"
