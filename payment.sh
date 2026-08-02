#!/bin/bash
app_name=payment

source ./common.sh

check_root

app_setup

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
validate $? "python3 installation"

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

systemd_setup

print_time

echo -e "$G Payment setup completed successfully. Time taken: $TOTAL_TIME seconds $N" | tee -a "$LOG_FILE"