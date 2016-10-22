#!/bin/bash

set -xe;

if [ -e ${VOLUME_LOCATION_BASE} ];
then
  VOLUME_LOCATION_BASE="~"
fi

VOLUME_LOCATION_BASE=$(readlink -e ${VOLUME_LOCATION_BASE})

if [ -e ${WORKERS} ];
then
  WORKERS="jenkins-slave-1 jenkins-slave-2"
fi

if [ -e ${START_PORT} ];
then
  START_PORT=23
fi


for WORKER_ID in ${WORKERS}; 
do

VOLUMES_LOCATION=${VOLUME_LOCATION_BASE}/${WORKER_ID}
mkdir -p ${VOLUMES_LOCATION}/jenkins_slave && chmod 777 ${VOLUMES_LOCATION}/jenkins_slave
mkdir -p ${VOLUMES_LOCATION}/docker_images && chmod 777 ${VOLUMES_LOCATION}/docker_images

docker run \
	--name ${WORKER_ID} \
	--privileged \
	-d \
	--restart=always \
	-p ${START_PORT}:22 \
	-v ${VOLUMES_LOCATION}/jenkins_slave:/home/jenkins/jenkins_slave \
	-v ${VOLUMES_LOCATION}/docker_images:/var/lib/docker \
	teradatalabs/jenkins-slave:latest

START_PORT=$[START_PORT+1]

done






