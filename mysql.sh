#!/bin/bash

source ./common.sh

check_root

echo "Enter MySQL root password:"
read -s MYSQL_ROOT_PASSWORD
echo



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

print_time

echo -e "$G MySQL setup completed successfully. Time taken: $TOTAL_TIME seconds $N" | tee -a "$LOG_FILE"