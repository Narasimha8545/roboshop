#!/bin/bash
START_TIME=$(date +%s)
R="\e[31m"
G="\e[32m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$( basename $0 |cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

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
        echo -e " $N $2 is .... $G successful $N" | tee -a $LOG_FILE
    else    
        echo -e " $N $2 is .... $R failed $N "| tee -a $LOG_FILE
        exit 1
    fi
}
dnf module disable nodejs -y &>>$LOG_FILE
validate $? "nodejs module disable"

dnf module enable nodejs:20 -y &>>$LOG_FILE
validate $? "nodejs module enable"

dnf install nodejs -y &>>$LOG_FILE
validate $? "nodejs"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then 
useradd --system --home /app --shell /sbin/nologin --comment "roboshop application user" roboshop &>>$LOG_FILE
validate $? "roboshop user creation"
else 
     echo -e " $G system user roboshop is already present $N " | tee -a $LOG_FILE
fi

mkdir -p /app &>>$LOG_FILE
validate $? "app directory creation"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
validate $? "user zip download"

rm -rf /app/* &>>$LOG_FILE
cd /app &>>$LOG_FILE
validate $? "changing directory to /app"

unzip /tmp/user.zip &>>$LOG_FILE 
validate $? "unzip user zip"

npm install &>>$LOG_FILE
validate $? "npm install"

cat >/etc/systemd/system/user.service <<EOF
[Unit]
Description = User Service
[Service]
User=roboshop
Environment=MONGO=true
// highlight-start
Environment=REDIS_URL='redis://redis.natureaws-84.shop:6379'
Environment=MONGO_URL="mongodb://mongodb.natureaws-84.shop:27017/users"
// highlight-end
ExecStart=/bin/node /app/server.js
SyslogIdentifier=user

[Install]
WantedBy=multi-user.target
EOF
validate $? "copying user.service file"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable user &>>$LOG_FILE
systemctl start user 
validate $? "starting user service"

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

echo -e "$G User setup completed successfully. Time taken: $TOTAL_TIME seconds $N" | tee -a "$LOG_FILE"