FROM ubuntu:16.04
MAINTAINER Teradata Docker Team <docker@teradata.com>

# Set Locale
RUN locale-gen en_US.UTF-8
COPY locale /etc/default/locale

# Change Mirror
RUN sed -i 's/http:\/\/archive.ubuntu.com\/ubuntu\//http:\/\/mirror.steadfast.net\/ubuntu\//g' /etc/apt/sources.list

# Update Packets
RUN apt-get update && apt-get -y dist-upgrade

# Install SSH
RUN apt-get install -y openssh-server && mkdir -p /var/run/sshd

# Install Supervisor D
RUN apt-get install -y supervisor && mkdir -p /var/log/supervisor

# Install Docker
RUN apt-get install -y software-properties-common apt-transport-https ca-certificates iptables lxc \
	&& yes | apt-get install -y linux-image-extra-$(uname -r) \
	&& yes | apt-get install -y linux-image-extra-virtual  \
	&& apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D \
	&& echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list \
	&& apt-get update \
	&& apt-get install -y docker-engine

# Install PIP
RUN apt-get install -y python-pip

# Install Docker Compose
RUN yes | pip install docker-compose

# Install Java
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections \
	&& add-apt-repository -y ppa:webupd8team/java \
	&& apt-get update \
	&& apt-get install -y oracle-java8-installer \
	&& apt-get install -y oracle-java8-set-default

# Setup SSH
COPY id_rsa.pub /tmp/id_rsa.pub
RUN mkdir -p ~/.ssh && cat /tmp/id_rsa.pub > ~/.ssh/authorized_keys

# Setup sudo
RUN apt-get install sudo

# Setup Jenkins User
RUN adduser jenkins  --disabled-password --gecos "" --shell /bin/bash \
	&& usermod -aG sudo jenkins \
	&& su - jenkins -c 'mkdir -p /home/jenkins/jenkins_slave' \
	&& su - jenkins -c 'mkdir -p /home/jenkins/.ssh' \
	&& su - jenkins -c 'touch /home/jenkins/.ssh/authorized_keys' \
	&& cat /tmp/id_rsa.pub >> /home/jenkins/.ssh/authorized_keys \
	&& usermod -aG docker jenkins \
	&& usermod -aG sudo jenkins \
	&& echo 'jenkins ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Setup Supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY limits.conf /etc/security/limits.conf
COPY sysctl.conf /etc/sysctl.conf

CMD ["/usr/bin/supervisord"]
	
