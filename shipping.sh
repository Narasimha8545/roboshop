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

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
validate $? "shipping zip download"

rm -rf /app/* &>>$LOG_FILE
cd /app &>>$LOG_FILE
validate $? "changing directory to /app"

unzip /tmp/shipping.zip &>>$LOG_FILE 
validate $? "unzip shipping zip"

mvn clean package &>>$LOG_FILE
validate $? "maven build"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
validate $? "rename shipping jar"

cat >/etc/systemd/system/shipping.service <<EOF
[Unit]
Description=Shipping Service

[Service]
User=roboshop
// highlight-start
Environment=CART_ENDPOINT=cart.natureaws-84.shop:8080
Environment=DB_HOST=mysql.natureaws-84.shop
// highlight-end
ExecStart=/bin/java -jar /app/shipping.jar
SyslogIdentifier=shipping

[Install]
WantedBy=multi-user.target
EOF
validate $? "copying shipping.service file"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable shipping &>>$LOG_FILE
systemctl start shipping &>>$LOG_FILE
validate $? "starting shipping service"

dnf install mysql -y &>>$LOG_FILE
validate $? "install mysql client"

mysql -h mysql.natureaws-84.shop -uroot -p$MYSQL_ROOT_PASSWORD -e 'use cities' 
if [ $? -ne 0 ]
then 
mysql -h mysql.natureaws-84.shop -uroot -p$MYSQL_ROOT_PASSWORD </app/db/schema.sql &>>$LOG_FILE
validate $? "shipping schema setup"

mysql -h mysql.natureaws-84.shop -uroot -p$MYSQL_ROOT_PASSWORD </app/db/app-uses.sql &>>$LOG_FILE
validate $? "shipping app user setup"

mysql -h mysql.natureaws-84.shop -uroot -p$MYSQL_ROOT_PASSWORD </app/db/master-data.sql &>>$LOG_FILE
validate $? "shipping master data setup"
else 
     echo -e " $G shipping schema is already present $N " | tee -a $LOG_FILE
fi
systemctl restart shipping &>>$LOG_FILE
validate $? "shipping service restart"


END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

echo -e "$G Cart setup completed successfully. Time taken: $TOTAL_TIME seconds $N" | tee -a "$LOG_FILE"