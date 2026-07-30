#!/bin/bash
R="\e[31m"
G="\e[32m"
B="\e[34m"
N="\e[0m" #normal color
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "script started excuting at: $(date)" |tee -a $LOG_FILE
#check the user is root or not
userid=$(id -u)
if [ $userid -ne 0 ]
then 
    echo -e " $R please run the script as root user $N " |tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo -e " $G your are running the root user $N " |tee -a $LOG_FILE
    fi
    # validate function takes the exist status, what command they tried to install
    validate() {
        if [ $1 -eq 0 ] 
        then
            echo -e " $G  $2 is .... successful $N" |tee -a $LOG_FILE
        else    
            echo -e " $R  $2 is .... failed $N "|tee -a $LOG_FILE
            exit 1
        fi 
    }

    cp mongodb.repo /etc/yum.repos.d/mongodb.repo &>>$LOG_FILE

    validate $? "mongo.repo"

    dnf install mongodb-org -y &>>$LOG_FILE

    validate $? "installing mongodb-org"

    systemctl enable mongod &>>$LOG_FILE

    validate $? "enable mongodb"

    systemctl start mongod &>>$LOG_FILE

    validate $? "start mongodb"

    sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>>$LOG_FILE

    validate $? "update mongod.conf"

    systemctl restart mongod &>>$LOG_FILE

    validate $? "restart mongodb"