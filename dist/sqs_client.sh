#!/bin/bash
# Author:      Hiroshi Wada
# Email:       hiroshi.wada@nicta.com.au
# Date:        Sept 24, 2013
# Description:
#
# This script enqueues a request into a given SQS queue. aws-cli must be
# installed and configured properly.
#
# Dependency:
#  aws-cli (https://github.com/aws/aws-cli) for sending a request to SQS
#

# auto die
set -e

# check if command exits
type aws > /dev/null 2>&1 || (echo "[$(date)] aws-cli is not installed" && return 1)

function send_request {
	local SQS_REGION=$1
	local SQS_QUEUE_URL=https://sqs.$SQS_REGION.amazonaws.com/${2%/}
	local MESSAGE=$3

	# send a request to SQS
	echo "[$(date)] Sending a request to SQS ($SQS_QUEUE_URL)"
	aws sqs send-message --region $SQS_REGION --queue-url $SQS_QUEUE_URL --message-body "$3" 
	echo "[$(date)] Finished sending a request"
}


if [ $# -ne 3 ]; then
	echo "usage: $(basename $0) region sqsid message"
	echo "  region   region name. eg us-west-1, ap-southeast-2"
	echo "  sqsid    SQL URL minus domain. eg 309657489351/comp2121"
	echo "  message  message to send"
	exit 1
fi

send_request $1 $2 "$3"
