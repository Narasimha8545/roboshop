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

check_root () {
    if [ $userid -ne 0 ]
    then 
         echo -e " $R please run the script as root user $N " | tee -a $LOG_FILE
         exit 1 #give other than 0 upto 127
    else
        echo -e " $G your are running the root user $N " | tee -a $LOG_FILE
    fi

    validate () {
    if [ $1 -eq 0 ]
    then
        echo -e " $N $2 is .... $G successful $N" | tee -a $LOG_FILE
    else    
        echo -e " $N $2 is .... $R failed $N "| tee -a $LOG_FILE
        exit 1
    fi
}
}
nodejs_setup () {
    dnf module disable nodejs -y &>>$LOG_FILE
    validate $? "nodejs module disable"

    dnf module enable nodejs:20 -y &>>$LOG_FILE
    validate $? "nodejs module enable"

    dnf install nodejs -y &>>$LOG_FILE
    validate $? "nodejs installation"

    npm install &>>$LOG_FILE
    validate $? "npm install"
}

app_setup () {
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

    curl -o /tmp/$app_name.zip https://roboshop-artifacts.s3.amazonaws.com/$app_name-v3.zip &>>$LOG_FILE
    validate $? "$app_name zip download"

    rm -rf /app/* &>>$LOG_FILE
    cd /app &>>$LOG_FILE
    validate $? "changing directory to /app"

    unzip /tmp/$app_name.zip &>>$LOG_FILE
    validate $? "unzip $app_name zip"
    }

mavn_setup () {
     dnf install maven -y &>>$LOG_FILE
     validate $? "maven installation"

      mvn clean package &>>$LOG_FILE
     validate $? "maven build"

     mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
     validate $? "rename shipping jar"

}

systemd_setup () {
    cp /home/centos/roboshop-shell/$app_name.service /etc/systemd/system/$app_name.service &>>$LOG_FILE
    validate $? "copying $app_name.service file"

    systemctl daemon-reload &>>$LOG_FILE
    validate $? "systemctl daemon-reload"

    systemctl enable $app_name &>>$LOG_FILE
    validate $? "enable $app_name service"

    systemctl start $app_name &>>$LOG_FILE
    validate $? "starting $app_name service"
}




print_time () {
    END_TIME=$(date +%s)
    TOTAL_TIME=$((END_TIME - START_TIME))
    echo -e "${G}Script completed in $TOTAL_TIME seconds.${N}" | tee -a $LOG_FILE
}