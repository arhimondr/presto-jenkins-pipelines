#!/bin/bash -ex

PID_FILE="/var/run/docker.pid"

if [ -e "${PID_FILE}" ]
then
	echo "PID file exists: ${PID_FILE}"
	PID=$(cat ${PID_FILE})
	if kill -0 $PID > /dev/null 2>&1; then
		echo "Another instance of dockerd is still runnin with PID: $PID"
		exit 1;
	fi
	rm ${PID_FILE}
fi 

/usr/bin/docker daemon \
	-H unix:///var/run/docker.sock \
	-p ${PID_FILE} \
	--insecure-registry=153.65.69.234:5000 \
	--registry-mirror=http://153.65.69.234:5000 \
	--dns 153.65.2.111 \
	--dns 8.8.8.8
