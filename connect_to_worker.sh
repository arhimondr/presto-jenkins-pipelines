#!/bin/bash -e

SCRIPT_DIRECTORY=${BASH_SOURCE%/*}
WORKER=$1

if [[ -z $WORKER ]];
then 
	echo "Usage: './connect_to_worker.sh <dupa-worker2_1>'"
	exit 1;
fi

HOST=$(echo $WORKER | perl -nle 'm/(dupa-worker\d+)_(\d+)/; print $1')
WORKER_NUMBER=$(echo $WORKER | perl -nle 'm/(dupa-worker\d+)_(\d+)/; print $2')

if [[ -z $HOST || -z $WORKER_NUMBER ]];
then
	echo "Worker format: '<dupa-workerN_M>'"
	exit 1;
fi

PORT=$((22 + $WORKER_NUMBER));


echo "Connecting to worker '$WORKER_NUMBER' at '$HOST:$PORT'.";

set -x
ssh -o StrictHostKeyChecking=no -i docker-images/teradatalabs/jenkins-slave/id_rsa jenkins@${HOST}.td.teradata.com -p ${PORT}
