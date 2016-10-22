FROM ubuntu:16.04
MAINTAINER Teradata Docker Team <docker@teradata.com>

# Update Packets
RUN apt-get update && apt-get -y dist-upgrade

# Install SSH
RUN apt-get install -y openssh-server && mkdir -p /var/run/sshd

# Install Supervisor D
RUN apt-get install -y supervisor && mkdir -p /var/log/supervisor

# Install apt-add-repository
RUN apt-get install -y software-properties-common

# Install Docker
RUN apt-get install -y apt-transport-https ca-certificates \
	&& apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D \
	&& echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list \
	&& apt-get update \
	&& apt-get install -y docker-engine \
	&& service docker start \
	&& docker run hello-world \

# Install PIP
RUN apt-get install -y python-pip

# Install Docker Compose
RUN pip install -y docker-compose

# Install Java
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections \
	&& add-apt-repository -y ppa:webupd8team/java \
	&& apt-get update \
	&& apt-get install -y oracle-java8-installer \
	&& apt-get install -y oracle-java8-set-default
	
