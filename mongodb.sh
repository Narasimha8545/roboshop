
source ./common.sh
app_name="mongodb"

check_root

 cat >/etc/yum.repos.d/mongo.repo <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
EOF

validate $? "Creating mongo.repo"

dnf install -y mongodb-org &>>"$LOG_FILE"
validate $? "Installing MongoDB"

systemctl enable mongod &>>"$LOG_FILE"
validate $? "Enable mongod"

systemctl start mongod &>>"$LOG_FILE"
validate $? "Start mongod"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>>"$LOG_FILE"
validate $? "Update mongod.conf"

systemctl restart mongod &>>"$LOG_FILE"
validate $? "Restart mongod"

print_time 