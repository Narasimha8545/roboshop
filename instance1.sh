#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-00e84a02e682ac879"

INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")

ZONE_ID="Z02640321D44PD6W59JI5"
DOMAIN_NAME="natureaws-84.shop"

for instance in "${INSTANCES[@]}"
do

echo "Creating $instance instance..."

if [ "$instance" == "frontend" ]
then
    PUBLIC_IP="--associate-public-ip-address"
else
    PUBLIC_IP=""
fi


INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type t3.micro \
    --security-group-ids "$SG_ID" \
    $PUBLIC_IP \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query "Instances[*].InstanceId" \
    --output text)


echo "$instance instance ID is $INSTANCE_ID"


sleep 10


if [ "$instance" != "frontend" ]
then

    IP=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --query "Reservations[*].Instances[*].PrivateIpAddress" \
        --output text)

else

    IP=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --query "Reservations[*].Instances[*].PublicIpAddress" \
        --output text)

fi


echo "$instance IP address is $IP"

done