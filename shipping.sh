#!/bin/bash
app_name=shipping
source ./common.sh
check_root

echo "enter the mysql root password"
read -s MYSQL_ROOT_PASSWORD 

app_setup


mvn_setup

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

systemd_setup

dnf install mysql -y &>>$LOG_FILE
validate $? "install mysql client"

mysql -h mysql.natureaws-84.shop -uroot -p$MYSQL_ROOT_PASSWORD -e 'use cities' 
if [ $? -ne 0 ]
then 
mysql -h mysql.natureaws-84.shop -uroot -p$MYSQL_ROOT_PASSWORD </app/db/schema.sql &>>$LOG_FILE
validate $? "shipping schema setup"

else 
     echo -e " $G shipping schema is already present $N " | tee -a $LOG_FILE
fi

mysql -h mysql.natureaws-84.shop -uroot -p$MYSQL_ROOT_PASSWORD </app/db/app-user.sql &>>$LOG_FILE
validate $? "shipping app user setup"

mysql -h mysql.natureaws-84.shop -uroot -p$MYSQL_ROOT_PASSWORD </app/db/master-data.sql &>>$LOG_FILE
validate $? "shipping master data setup"

systemctl restart shipping &>>$LOG_FILE
validate $? "shipping service restart"

print_time

echo -e "$G Shipping setup completed successfully. Time taken: $TOTAL_TIME seconds $N" | tee -a "$LOG_FILE"