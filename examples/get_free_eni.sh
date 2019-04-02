#!/bin/bash

export AWS_DEFAULT_REGION="us-east-1"
FREE_ENI=$(aws ec2 describe-network-interfaces --network-interface-ids eni-bc00a2a3 --filters Name=status,Values=available --query NetworkInterfaces[0].NetworkInterfaceId | sed s/\"//g)
aws ec2 attach-network-interface --network-interface-id $FREE_ENI --instance-id $(curl -s http://169.254.169.254/latest/meta-data/instance-id) --device-index 1
ENI_IP=$(aws ec2 describe-network-interfaces --network-interface-ids $FREE_ENI --query NetworkInterfaces[0].PrivateIpAddress | sed s/\"//g)


