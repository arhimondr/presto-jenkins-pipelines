#!/bin/bash

set -xe;

VOLUME_LOCATION_BASE=/tmp
WORKER_ID=jenkins-slave-1-1-temp
WORKER_SSH_PORT=23

VOLUMES_LOCATION=${VOLUME_LOCATION_BASE}/${WORKER_ID}
mkdir -p ${VOLUMES_LOCATION}/jenkins_slave && chmod 777 ${VOLUMES_LOCATION}/jenkins_slave
mkdir -p ${VOLUMES_LOCATION}/docker_images && chmod 777 ${VOLUMES_LOCATION}/docker_images

docker run \
	--name ${WORKER_ID} \
	--privileged \
	-d \
	--restart=always \
	-p ${WORKER_SSH_PORT}:22 \
	-v ${VOLUMES_LOCATION}/jenkins_slave:/home/jenkins/jenkins_slave \
	-v ${VOLUMES_LOCATION}/docker_images:/var/lib/docker \
	teradatalabs/jenkins-slave:latest
