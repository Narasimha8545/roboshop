#!/bin/bash
START_TIME=$(date +%s)
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
        echo -e " $N $2 is .... $G successful $N" | tee -a $LOG_FILE
    else    
        echo -e " $N $2 is .... $R failed $N "| tee -a $LOG_FILE
        exit 1
    fi
}
dnf module disable redis -y &>>$LOG_FILE
validate $? "redis module disable"

dnf module enable redis:7 -y &>>$LOG_FILE
validate $? "redis module enable"

dnf install redis -y &>>$LOG_FILE
validate $? "redis"

sed -i 's/127.0.0.1/0.0.0.0/g; s/protected-mode yes/protected-mode no/g'  /etc/redis.conf &>>$LOG_FILE
validate $? "redis configuration"

systemctl enable redis &>>$LOG_FILE
validate $? "enabling the redis"

systemctl restart redis &>>$LOG_FILE
validate $? "restarting the redis"