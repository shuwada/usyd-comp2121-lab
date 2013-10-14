#!/bin/bash
# Author:      Hiroshi Wada
# Email:       hiroshi.wada@nicta.com.au
# Date:        Sept 24, 2013
# Description:
#
# Dependency:
#  - aws-cli (https://github.com/aws/aws-cli) to monitor EC2 instances
#

# auto die
set -e

# check if command exits
type aws > /dev/null 2>&1 || (echo "[$(date)] aws-cli is not installed" && return 1)

# parameters
MAX_QUEUE_LENGTH=9

function launch_instance_if_necessary {
	local SQS_REGION=$1
	local SQS_QUEUE_URL=https://sqs.$SQS_REGION.amazonaws.com/${2%/}
	local AMI_ID=$3

	# get the number of instances
	local NUM_INSTANCES=$(aws ec2 describe-instances --output text | grep $AMI_ID | wc -l)
	if [ $NUM_INSTANCES -gt 0 ]; then
		echo "[$(date)] There are $NUM_INSTANCES instances of $AMI_ID. Do not launch a new one."
		return;
	fi

	# get the approxymate # of messages in the queue
	# if there are more than $MAX_QUEUE_LENGTH, launch one
	local MSG="$(aws sqs get-queue-attributes --attribute-names ApproximateNumberOfMessages --queue-url $SQS_QUEUE_URL)"
	local NUM_REQ="$(echo $MSG | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["Attributes"]["ApproximateNumberOfMessages"]')"
	echo "[$(date)] There are $NUM_REQ requests waiting in the queue ($SQS_QUEUE_URL)"
	if [ $NUM_REQ -gt $MAX_QUEUE_LENGTH ]; then
		echo "[$(date)] too many requests are waiting. launch a new instance"
		aws ec2 run-instances --image-id $AMI_ID
		return;
	fi

	# do nothing
	echo "[$(date)] No need to launch a new instance"
}


if [ $# -ne 3 ]; then
	echo "usage: $(basename $0) region sqsid ami-id"
	echo "  region   region name. eg us-west-1, ap-southeast-2"
	echo "  sqsid    SQL URL minus domain. eg 309657489351/comp2121"
	echo "  ami-id   id of AMI to launch"
	exit 1
fi

launch_instance_if_necessary $1 $2 "$3"
