#!/bin/bash

SG_ID="sg-0d19e8684e6f602f7" #replace with your ID
AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z074576211J1G0FY8HEVU"
DOMAIN_NAME="kayasiri.online"
for instance in $@
do 
    INSTANCE_ID=$( aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type "t3.micro" \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text )

    if [ $instance == "frontend" ]; then
         IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PublicIpAddress' \
             --output text

         )
            RECORD_NAME="$DOMAIN_NAME" #kayasiri.online
    else
          IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
             --output text
          )

          RECORD_NAME="$instance.$DOMAIN_NAME" #mongodb.kayasiri.online
    fi

    echo  " IP Address is $IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
       "Comment": "updating record",
       "Changes": [
            {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$RECORD_NAME'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [
                {
                    "Value": "'$IP'"
                }
                ]
            }
            }
        ]
    }
    '
      echo "record updated for $instance"

          
    
done