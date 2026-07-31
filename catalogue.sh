#!/bin/bash

R="\e[31m"
G="\e[32m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$( basename $0 |cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD
DOMAIN="mongodb.natureaws-84.shop"

mkdir -p $LOGS_FOLDER

userid=$(id -u)
if [ $userid -ne 0 ]
then 
     echo -e " $R please run the script as root user $N " | tee -a $LOG_FILE
     exit 1 #give other than 0 upto 127
else
    echo -e " $G your are running the root user $N " | tee -a $LOG_FILE
fi
validate() {
    if [ $1 -eq 0 ]
    then
        echo -e " $G $2 is .... successful $N" | tee -a $LOG_FILE
    else    
        echo -e " $R $2 is .... failed $N "| tee -a $LOG_FILE
        exit 1
    fi
}
dnf module disable nodejs -y &>>$LOG_FILE
validate $? "nodejs module disable"

dnf module enable nodejs:20 -y &>>$LOG_FILE
validate $? "nodejs module enable"

dnf install nodejs -y &>>$LOG_FILE
validate $? "nodejs"

#useradd --system --home /app --shell /sbin/nologin --comment "roboshop application user" roboshop &>>$LOG_FILE
#validate $? "roboshop user creation"

mkdir -p /app &>>$LOG_FILE
validate $? "app directory creation"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
validate $? "catalogue zip download"

cd /app &>>$LOG_FILE
validate $? "changing directory to /app"

unzip /tmp/catalogue.zip &>>$LOG_FILE
validate $? "unzip catalogue zip"

npm install &>>$LOG_FILE
validate $? "npm install"

cat >/etc/systemd/system/catalogue.service <<EOF
[Unit]
Description = Catalogue Service

[Service]
User=roboshop
Environment=MONGO=true
// highlight-start
Environment=MONGO_URL="mongodb://$DOMAIN:27017/catalogue"
// highlight-end
ExecStart=/bin/node /app/server.js
SyslogIdentifier=catalogue

[Install]
WantedBy=multi-user.target
EOF 
validate $? "copying catalogue.service file"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue &>>$LOG_FILE
systemctl start catalogue 
validate $? "starting catalogue service"

cat > /etc/yum.repos.d/mongo.repo <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/7.0/x86_64/
enabled=1
gpgcheck=0
EOF &>>$LOG_FILE
dnf install mongodb-mongosh -y &>>$LOG_FILE
validate $? "installing mongodb-mongosh"

mongosh --host $DOMAIN  </app/db/master-data.js &>>$LOG_FILE
validate $? "loading catalogue schema"