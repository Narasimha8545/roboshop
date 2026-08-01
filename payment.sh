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

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
validate $? "python3 installation"


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

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v1.zip &>>$LOG_FILE
validate $? "payment zip download"

rm -rf /app/* &>>$LOG_FILE
cd /app &>>$LOG_FILE
validate $? "changing directory to /app"

unzip /tmp/payment.zip &>>$LOG_FILE 
validate $? "unzip payment zip"

pip3 install -r requirements.txt &>>$LOG_FILE
validate $? "python3 requirements installation"

cat > /etc/systemd/system/payment.service <<EOF
[Unit]
Description=Payment Service

[Service]
User=root
WorkingDirectory=/app
// highlight-start
Environment=CART_HOST=cart.natureaws-84.shop
Environment=CART_PORT=8080
Environment=USER_HOST=user.natureaws-84.shop
Environment=USER_PORT=8080
Environment=AMQP_HOST=rabbitmq.natureaws-84.shop
// highlight-end
Environment=AMQP_USER=roboshop
Environment=AMQP_PASS=roboshop123

ExecStart=/usr/local/bin/uwsgi --ini payment.ini
ExecStop=/bin/kill -9 $MAINPID
SyslogIdentifier=payment

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload &>>$LOG_FILE
validate $? "daemon reload"

systemctl enable payment &>>$LOG_FILE
validate $? "enable payment service"

systemctl start payment &>>$LOG_FILE
validate $? "starting payment service"

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

echo -e "$G Cart setup completed successfully. Time taken: $TOTAL_TIME seconds $N" | tee -a "$LOG_FILE"