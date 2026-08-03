#!/bin/bash

R="\e[31m"
G="\e[32m"

LOG_FOLDER="/etc/var/roboshop_logs"
SCRIPT_NAME=$(basename "$0" | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SOURCE_DIR=$(/home/ec2-user/app-logs)

mkdir -p "$LOG_FOLDER"

userid=$(id -u) 
if [ $userid -ne 0 ]; 
  then
     echo -e "${R}You should run this script as root user or with sudo privileges.${N}"
     exit 1
else
    echo -e "${G}You are running the script as root user.${N}"
fi

validate () {
    if [ $1 -eq 0 ]
    then 
        echo -e "${G}$2 success${N}" | tee -a "$LOG_FILE"
    else
        echo -e "${R}$2 failed. Check the log file for more details: $LOG_FILE${N}" | tee -a "$LOG_FILE"
        exit 1
    fi
}



echo -e "script execution started at $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"

FILES_TO_DELETE=$(find SOURCE_DIR -name "*.log" -mtime +10)
while IFS= read -r filepath
do 
    rm -f "$filepath" &>>"$LOG_FILE"
    validate $? "Deleting $filepath"
done <<< "$FILES_TO_DELETE"

echo -e "script execution completed at $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
