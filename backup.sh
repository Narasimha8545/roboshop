#!/bin/bash

START_TIME=$(date +%s)

R="\e[31m"
G="\e[32m"
N="\e[0m"

SOURCE_DIR=$1
DEST_DIR=$2
DAYS=${3:-14}    # Default is 14 days if not provided

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename "$0" | cut -d "." -f1)

mkdir -p "$LOGS_FOLDER"

LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

USERID=$(id -u)

check_root() {
    if [ "$USERID" -ne 0 ]
    then
        echo -e "${R}Please run the script as root user${N}" | tee -a "$LOG_FILE"
        exit 1
    else
        echo -e "${G}You are running as root user${N}" | tee -a "$LOG_FILE"
    fi
}

validate() {
    if [ "$1" -eq 0 ]
    then
        echo -e "${G}$2 ... Successful${N}" | tee -a "$LOG_FILE"
    else
        echo -e "${R}$2 ... Failed${N}" | tee -a "$LOG_FILE"
        exit 1
    fi
}

usage() {
    echo -e "${R}USAGE:${N} sh backup.sh <source_directory> <destination_directory> <days(optional)>"
}

# Check root user
check_root

# Check arguments
if [ $# -lt 2 ]
then
    usage
    exit 1
fi

# Check source directory
if [ ! -d "$SOURCE_DIR" ]
then
    echo -e "${R}Source directory '$SOURCE_DIR' does not exist.${N}" | tee -a "$LOG_FILE"
    exit 1
fi

# Check destination directory
if [ ! -d "$DEST_DIR" ]
then
    echo -e "${R}Destination directory '$DEST_DIR' does not exist.${N}" | tee -a "$LOG_FILE"
    exit 1
fi

# Find log files older than DAYS
FILES=$(find "$SOURCE_DIR" -name "*.log" -mtime +$DAYS)


if [ ! -z "$FILE" ]
then
    echo -e "${G}Found the following log files older than $DAYS days:${N}" | tee -a "$LOG_FILE"
    echo "$FILES" | tee -a "$LOG_FILE"
else
    echo -e "${G}No log files older than $DAYS days found in '$SOURCE_DIR'.${N}" | tee -a "$LOG_FILE"
fi
