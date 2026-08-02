#!/bin/bash
app_name=user
source ./common.sh

check_root 

app_setup 

nodejs_setup


cat >/etc/systemd/system/user.service <<EOF
[Unit]
Description = User Service
[Service]
User=roboshop
Environment=MONGO=true
// highlight-start
Environment=REDIS_URL="redis://redis.natureaws-84.shop:6379"
Environment=MONGO_URL="mongodb://mongodb.natureaws-84.shop:27017/users"
// highlight-end
ExecStart=/bin/node /app/server.js
SyslogIdentifier=user

[Install]
WantedBy=multi-user.target
EOF
validate $? "copying user.service file"

systemd_setup

print_time

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

echo -e "$G User setup completed successfully. Time taken: $TOTAL_TIME seconds $N" | tee -a "$LOG_FILE"