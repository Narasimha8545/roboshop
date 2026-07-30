#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-00e84a02e682ac879"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z02640321D44PD6W59JI5"
DOMAIN_NAME="natureaws-84.shop"

for instance in ${INSTANCES[@]}
do
INSTANCE_ID=$(aws ec2 run-instances \
             --image-id ami-0220d79f3f480ecf5 \
             --instance-type t3.micro \
             --security-group-ids sg-00e84a02e682ac879 \
             --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}] \
             --query "Instances[*].instanceid" \
             --output text)
if [ $instance != "frontend" ]
then
     IP=$(aws ec2 describe-instances \
      --instance-ids $INSTANCE_ID \
      --query "Reservations[*].Instances[*].PrivateIpAddress" \
      --output text)
else
     IP=$(aws ec2 describe-instances \
      --instance-ids $INSTANCE_ID \
      --query "Reservations[*].Instances[*].PublicIpAddress" \
      --output text)
fi
echo "$instance ip address is $IP"
done 