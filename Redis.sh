
#!/bin/bash
app_name=redis
source ./common.sh

check_root 

# Check whether Redis is already installed
rpm -q redis &>> "$LOG_FILE"

if [ $? -eq 0 ]
then
    echo -e "$G Redis is already installed. Exiting... $N" | tee -a "$LOG_FILE"
    exit 0
else

    dnf module disable redis -y &>> "$LOG_FILE"
    validate $? "redis module disable"

    dnf module enable redis:7 -y &>> "$LOG_FILE"
    validate $? "redis module enable"

    dnf install redis -y &>> "$LOG_FILE"
    validate $? "redis installation"



# Redis configuration
sed -i 's/127.0.0.1/0.0.0.0/g; s/protected-mode yes/protected-mode no/g' /etc/redis/redis.conf &>> "$LOG_FILE"
validate $? "redis configuration"

# Enable Redis service
systemctl enable redis &>> "$LOG_FILE"
validate $? "enabling redis"

# Restart Redis service
systemctl restart redis &>> "$LOG_FILE"
validate $? "restarting redis"

print_time

echo -e "$G Redis setup completed successfully. Time taken: $TOTAL_TIME seconds $N" | tee -a "$LOG_FILE"
fi