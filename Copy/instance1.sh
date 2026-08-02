#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-00e84a02e682ac879"

INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")

ZONE_ID="Z02640321D44PD6W59JI5"
DOMAIN_NAME="natureaws-84.shop"

# Check AWS credentials before starting
aws sts get-caller-identity > /dev/null 2>&1

if [ $? -ne 0 ]
then
    echo "AWS credentials not configured. Run: aws configure"
    exit 1
fi


for instance in "${INSTANCES[@]}"
do

echo "Creating $instance instance..."

# Assign public IP only for frontend
if [ "$instance" == "frontend" ]
then
    PUBLIC_IP="--associate-public-ip-address"
else
    PUBLIC_IP=""
fi


INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type t2.micro \
    --security-group-ids "$SG_ID" \
    $PUBLIC_IP \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query "Instances[0].InstanceId" \
    --output text)


if [ -z "$INSTANCE_ID" ]
then
    echo "Failed to create $instance instance"
    continue
fi


echo "$instance instance ID is $INSTANCE_ID"


echo "Waiting for IP address..."
sleep 15


if [ "$instance" != "frontend" ]
then

    IP=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --query "Reservations[0].Instances[0].PrivateIpAddress" \
        --output text)

else

    IP=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --query "Reservations[0].Instances[0].PublicIpAddress" \
        --output text)

fi


echo "$instance IP address is $IP"

done