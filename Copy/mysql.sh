#!/bin/bash

START_TIME=$(date +%s)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename "$0" | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p "$LOGS_FOLDER"

USER_ID=$(id -u)

if [ "$USER_ID" -ne 0 ]; then
    echo -e "${R}Please run this script as root.${N}" | tee -a "$LOG_FILE"
    exit 1
else
    echo -e "${G}Running as root user.${N}" | tee -a "$LOG_FILE"
fi

echo "Enter MySQL root password:"
read -s MYSQL_ROOT_PASSWORD
echo

validate() {
    if [ "$1" -eq 0 ]; then
        echo -e "${G}$2 ... SUCCESS${N}" | tee -a "$LOG_FILE"
    else
        echo -e "${R}$2 ... FAILED${N}" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Install MySQL Server
dnf install mysql-server -y &>>"$LOG_FILE"
validate $? "Installing MySQL Server"

# Enable MySQL Service
systemctl enable mysqld &>>"$LOG_FILE"
validate $? "Enabling MySQL service"

# Start MySQL Service
systemctl start mysqld &>>"$LOG_FILE"
validate $? "Starting MySQL service"

# Check if root password is already set
mysql -h localhost -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" &>/dev/null

if [ $? -ne 0 ]; then
    mysql_secure_installation --set-root-pass "${MYSQL_ROOT_PASSWORD}" &>>"$LOG_FILE"
    validate $? "Setting MySQL root password"
else
    echo -e "${Y}MySQL root password is already configured. Skipping.${N}" | tee -a "$LOG_FILE"
fi

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

echo -e "${G}MySQL setup completed successfully. Time taken: ${TOTAL_TIME} seconds.${N}" | tee -a "$LOG_FILE"