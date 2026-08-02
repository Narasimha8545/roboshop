#!/bin/bash

# Get the script directory and source common.sh
source ./common.sh

app_name="mongodb"

# Check if the script is run as root
check_root

# Create MongoDB repository
cat >/etc/yum.repos.d/mongo.repo <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
EOF

validate $? "Creating MongoDB repository"

# Install MongoDB
dnf install -y mongodb-org &>>"$LOG_FILE"
validate $? "Installing MongoDB"

# Enable MongoDB service
systemctl enable mongod &>>"$LOG_FILE"
validate $? "Enabling mongod service"

# Start MongoDB service
systemctl start mongod &>>"$LOG_FILE"
validate $? "Starting mongod service"

# Allow remote connections
sed -i 's/^  bindIp: 127.0.0.1/  bindIp: 0.0.0.0/' /etc/mongod.conf &>>"$LOG_FILE"
validate $? "Updating mongod.conf"

# Restart MongoDB
systemctl restart mongod &>>"$LOG_FILE"
validate $? "Restarting mongod"

print_time

echo "MongoDB installation completed successfully."