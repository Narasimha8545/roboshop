#!/bin/bash
START_TIME=$(date +%s)
R="\e[31m"
G="\e[32m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$( basename $0 |cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
app_name=catalogue
mkdir -p $LOGS_FOLDER

source ./common.sh

check_root 

app_setup 

nodejs_setup

cat >/etc/systemd/system/catalogue.service <<EOF
[Unit]
Description=Catalogue Service

[Service]
User=roboshop
Environment=MONGO=true
Environment=MONGO_URL=mongodb://mongodb.natureaws-84.shop:27017/catalogue
ExecStart=/bin/node /app/server.js
SyslogIdentifier=catalogue

[Install]
WantedBy=multi-user.target
EOF
validate $? "copying catalogue.service file"

systemd_setup 

cat >/etc/yum.repos.d/mongo.repo <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
EOF

dnf install mongodb-mongosh -y &>>$LOG_FILE
validate $? "installing mongodb-mongosh"

STATUS=$(mongosh --quiet --host "$DOMAIN" --eval 'db.getSiblingDB("catalogue").products.countDocuments()')

if [ "$STATUS" -eq 0 ]
then
    mongosh --host "$DOMAIN" </app/db/master-data.js &>>"$LOG_FILE"
    validate $? "Loading catalogue schema"
else
    echo -e "${G}Catalogue data already exists. Skipping.${N}"
fi

print_time

echo -e "${G}Catalogue setup completed successfully.${N}" | tee -a "$LOG_FILE"