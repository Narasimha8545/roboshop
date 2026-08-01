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

echo "enter the mysql root password"
read -s MYSQL_ROOT_PASSWORD 

validate() {
    if [ $1 -eq 0 ]
    then
        echo -e " $N $2 is .... $G successful $N" | tee -a $LOG_FILE
    else    
        echo -e " $N $2 is .... $R failed $N "| tee -a $LOG_FILE
        exit 1
    fi
}

dnf install mysql -y &>>$LOG_FILE
validate $? "mysql installation"

systemctl enable mysqld &>>$LOG_FILE
validate $? "mysql service enable"

systemctl start mysqld &>>$LOG_FILE
validate $? "mysql service start"

mysql_secure_installation --set-root-pass "$MYSQL_ROOT_PASSWORD" &>>$LOG_FILE
validate $? "mysql root password set"

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

echo -e "$G User setup completed successfully. Time taken: $TOTAL_TIME seconds $N" | tee -a "$LOG_FILE"