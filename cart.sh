#!/bin/bash
app_name=cart
source ./common.sh

check_root 

app_setup 

nodejs_setup



cat >/etc/systemd/system/cart.service <<EOF
[Unit]
Description = Cart Service
[Service]
User=roboshop
// highlight-start
Environment=REDIS_HOST=redis.natureaws-84.shop
Environment=CATALOGUE_HOST=catalogue.natureaws-84.shop
Environment=CATALOGUE_PORT=8080
// highlight-end
ExecStart=/bin/node /app/server.js
SyslogIdentifier=cart

[Install]
WantedBy=multi-user.target
EOF
validate $? "copying cart.service file"

print_time

echo -e "$G Cart setup completed successfully. Time taken: $TOTAL_TIME seconds $N" | tee -a "$LOG_FILE"