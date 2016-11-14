#!/bin/bash

set -xe;

if [ -e ${VOLUME_LOCATION_BASE} ];
then
  VOLUME_LOCATION_BASE=${HOME}
fi

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
mkdir -p ${VOLUMES_LOCATION}/.m2 && chmod 777 ${VOLUMES_LOCATION}/.m2

docker rm -f ${WORKER_ID} || true
docker pull teradatalabs/jenkins-slave:latest
docker run \
	--name ${WORKER_ID} \
	--privileged \
	--cpu-shares=50 \
	--ulimit nofile=16384:16384 \
	-d \
	--restart=always \
	-p ${START_PORT}:22 \
	-v ${VOLUMES_LOCATION}/jenkins_slave:/home/jenkins/jenkins_slave \
	-v ${VOLUMES_LOCATION}/docker_images:/var/lib/docker \
	-v ${VOLUMES_LOCATION}/.m2:/home/jenkins/.m2 \
	teradatalabs/jenkins-slave:latest

START_PORT=$[START_PORT+1]

done

