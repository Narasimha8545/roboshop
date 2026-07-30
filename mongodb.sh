#!/bin/bash

R="\e[31m"
G="\e[32m"
B="\e[34m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename "$0" .sh)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p "$LOGS_FOLDER"

echo "Script started executing at: $(date)" | tee -a "$LOG_FILE"

# Check whether the user is root
USER_ID=$(id -u)

if [ "$USER_ID" -ne 0 ]
then
    echo -e "${R}Please run the script as root user${N}" | tee -a "$LOG_FILE"
    exit 1
else
    echo -e "${G}You are running as root user${N}" | tee -a "$LOG_FILE"
fi

# Function to validate command execution
validate() {
    if [ "$1" -eq 0 ]
    then
        echo -e "${G}$2 ... SUCCESS${N}" | tee -a "$LOG_FILE"
    else
        echo -e "${R}$2 ... FAILED${N}" | tee -a "$LOG_FILE"
        exit 1
    fi
}

cp mongodb.repo /etc/yum.repos.d/mongodb.repo &>>"$LOG_FILE"
validate $? "Copy mongodb.repo"

dnf install mongodb-org -y &>>"$LOG_FILE"
validate $? "Install mongodb-org"

systemctl enable mongod &>>"$LOG_FILE"
validate $? "Enable mongod"

systemctl start mongod &>>"$LOG_FILE"
validate $? "Start mongod"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>>"$LOG_FILE"
validate $? "Update mongod.conf"

systemctl restart mongod &>>"$LOG_FILE"
validate $? "Restart mongod"