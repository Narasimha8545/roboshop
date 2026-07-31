#!/bin/bash

R="\e[31m"
G="\e[32m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename "$0" | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p "$LOGS_FOLDER"

userid=$(id -u)

if [ "$userid" -ne 0 ]
then
    echo -e "${R}Please run the script as root user${N}" | tee -a "$LOG_FILE"
    exit 1
else
    echo -e "${G}Running as root user${N}" | tee -a "$LOG_FILE"
fi

validate() {
    if [ "$1" -eq 0 ]
    then
        echo -e "${G}$2 ... SUCCESS${N}" | tee -a "$LOG_FILE"
    else
        echo -e "${R}$2 ... FAILED${N}" | tee -a "$LOG_FILE"
        exit 1
    fi
}

dnf module disable nginx -y &>>"$LOG_FILE"
validate $? "Disable default nginx module"

dnf module enable nginx:1.24 -y &>>"$LOG_FILE"
validate $? "Enable nginx 1.24 module"

dnf install nginx -y &>>"$LOG_FILE"
validate $? "Install nginx"

systemctl enable nginx &>>"$LOG_FILE"
validate $? "Enable nginx"

systemctl start nginx &>>"$LOG_FILE"
validate $? "Start nginx"

rm -rf /usr/share/nginx/html/* &>>"$LOG_FILE"
validate $? "Remove default website"

curl -L -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>"$LOG_FILE"
validate $? "Download frontend"

cd /usr/share/nginx/html
validate $? "Change directory"

unzip -o /tmp/frontend.zip &>>"$LOG_FILE"
validate $? "Extract frontend"

rm -f /etc/nginx/nginx.conf &>>"$LOG_FILE"
validate $? "Remove default nginx.conf"

cat >/etc/nginx/nginx.conf <<EOF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    keepalive_timeout 65;
    types_hash_max_size 4096;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    include /etc/nginx/conf.d/*.conf;

    server {
        listen 80;
        listen [::]:80;
        server_name _;
        root /usr/share/nginx/html;

        include /etc/nginx/default.d/*.conf;

        error_page 404 /404.html;
        location = /404.html { }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html { }

        location /images/ {
            expires 5s;
            root /usr/share/nginx/html;
            try_files \$uri /images/placeholder.jpg;
        }

        location /api/catalogue/ {
            proxy_pass http://localhost:8080/;
        }

        location /api/user/ {
            proxy_pass http://localhost:8080/;
        }

        location /api/cart/ {
            proxy_pass http://localhost:8080/;
        }

        location /api/shipping/ {
            proxy_pass http://localhost:8080/;
        }

        location /api/payment/ {
            proxy_pass http://localhost:8080/;
        }

        location /health {
            stub_status on;
            access_log off;
        }
    }
}
EOF

validate $? "Create nginx.conf"

nginx -t &>>"$LOG_FILE"
validate $? "Validate nginx configuration"

systemctl restart nginx &>>"$LOG_FILE"
validate $? "Restart nginx"

echo -e "${G}Frontend setup completed successfully.${N}"