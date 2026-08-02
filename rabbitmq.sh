#!/bin/bash



echo "Enter RabbitMQ password:"
read -s RABBITMQ_PASSWORD
echo

check_root

# Configure RabbitMQ repository
cat >/etc/yum.repos.d/rabbitmq.repo <<'EOF'
[modern-erlang]
name=modern-erlang-el9
baseurl=https://yum1.novemberain.com/erlang/el/9/$basearch
        https://yum2.novemberain.com/erlang/el/9/$basearch
        https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/rpm/el/9/$basearch
enabled=1
gpgcheck=0

[modern-erlang-noarch]
name=modern-erlang-el9-noarch
baseurl=https://yum1.novemberain.com/erlang/el/9/noarch
        https://yum2.novemberain.com/erlang/el/9/noarch
        https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/rpm/el/9/noarch
enabled=1
gpgcheck=0

[rabbitmq-el9]
name=rabbitmq-el9
baseurl=https://yum1.novemberain.com/rabbitmq/el/9/$basearch
        https://yum2.novemberain.com/rabbitmq/el/9/$basearch
        https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-server/rpm/el/9/$basearch
enabled=1
gpgcheck=0

[rabbitmq-el9-noarch]
name=rabbitmq-el9-noarch
baseurl=https://yum1.novemberain.com/rabbitmq/el/9/noarch
        https://yum2.novemberain.com/rabbitmq/el/9/noarch
        https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-server/rpm/el/9/noarch
enabled=1
gpgcheck=0
EOF

validate $? "Creating RabbitMQ repo"

# Clean old metadata
dnf clean all &>>"$LOG_FILE"

# Install RabbitMQ
dnf install rabbitmq-server -y &>>"$LOG_FILE"
validate $? "Installing RabbitMQ Server"

# Enable service
systemctl enable rabbitmq-server &>>"$LOG_FILE"
validate $? "Enabling RabbitMQ"

# Start service
systemctl start rabbitmq-server &>>"$LOG_FILE"
validate $? "Starting RabbitMQ"

# Create user only if it doesn't exist
rabbitmqctl list_users | grep -q "^roboshop"

if [ $? -ne 0 ]; then
    rabbitmqctl add_user roboshop "$RABBITMQ_PASSWORD" &>>"$LOG_FILE"
    validate $? "Creating RabbitMQ user"
else
    echo -e "${Y}RabbitMQ user already exists...SKIPPING${N}" | tee -a "$LOG_FILE"
fi

# Set permissions
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>"$LOG_FILE"
validate $? "Setting RabbitMQ permissions"

print_time

echo -e "$G RabbitMQ setup completed successfully. Time taken: $TOTAL_TIME seconds $N" | tee -a "$LOG_FILE"