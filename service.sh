#!/bin/bash
# Author:      Hiroshi Wada
# Email:       hiroshi.wada@nicta.com.au
# Date:        Sept 24, 2013
# Description:
#
# This script does
#  1. Pull a request from an existing SQS queue (see SQS_QUEUE_URL)
#  2. Run sysbench to artificially incrase CPU load
#
# Dependency:
#  aws-cli (https://github.com/aws/aws-cli) for receiving a request to SQS
#  sysbench
#

# auto die
set -e

# Assume the SQS queue exists already
SQS_REGION=ap-southeast-2

# URI of the queue to watch
# e.g., SQS_QUEUE_URL=https://sqs.$SQS_REGION.amazonaws.com/517039496984/myqueue
SQS_QUEUE_URL=https://sqs.$SQS_REGION.amazonaws.com/517039496984/your-queue-name-comes-here

# check if command exits
type aws   > /dev/null 2>&1 || (echo "[$(date)] aws-cli is not installed" && return 1)

function process {
	# get the request from SQS
	echo "[$(date)] Pulling a request from $SQS_QUEUE_URL"
	local MSG="$(aws sqs receive-message --region $SQS_REGION --queue-url $SQS_QUEUE_URL --max-number-of-messages 1)"

	# do nothing if no request was obtained
	echo $MSG | grep -q "MessageId" || (echo "[$(date)] No request found in the queue" && return 1);
	
	# get the request body
	local BODY="$(echo $MSG | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["Messages"][0]["Body"]')"

	# run sysbench for 30 sec
	sysbench --test=cpu --max-time=30 run

	# delete the SQS message
	local HANDLE=$(echo $MSG | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["Messages"][0]["ReceiptHandle"]')
	aws sqs delete-message --region $SQS_REGION --queue-url $SQS_QUEUE_URL --receipt-handle $HANDLE

	echo "[$(date)] Completed"
}

ME=$(basename $0 .sh)

# do nothing if a previous process is still running
exec 8>"/tmp/$ME.LCK";
if flock -n -x 8; then
  process
else
  echo "[$(date)] Previous process of $ME is still running" && return 1
fi
