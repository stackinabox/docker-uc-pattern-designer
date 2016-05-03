FROM ubuntu:14.04

MAINTAINER Tim Pouyer <tpouyer@us.ibm.com>

RUN export DEBIAN_FRONTEND=noninteractive && \
    echo export LC_ALL=en_US.UTF-8 >> ~/.bash_profile && \
    echo export LANG=en_US.UTF-8 >> ~/.bash_profile && \
    mkdir -p /etc/apt/apt.config.d && \
    echo 'APT::Install-Recommends "0";' | tee --append /etc/apt/apt.config.d/99local > /dev/null && \
    echo 'APT::Install-Suggests "0";' | tee --append /etc/apt/apt.config.d/99local > /dev/null && \
    which add-apt-repository || (apt-get -qqy update ; apt-get -qqy install software-properties-common) && \
	apt-get -qqy update && \
	apt-get -qqy install python-pip \
	python-dev \
	git \
	wget \
	unzip \
	curl \
	logrotate \
	tar \
	gzip \
	openssh-server \
	postgresql-client-* \
	supervisor && \
	pip install -U pbr && \
	pip install -U pip && \
	apt-get clean && \
	apt-get purge && \
	rm -rf /var/lib/apt/lists/* 

ENV LICENSE_SERVER_URL ${LICENSE_SERVER_URL:-$LICENSE_SERVER_URL}
ENV WEB_SERVER_HOSTNAME ${WEB_SERVER_HOSTNAME:-$HOSTNAME}

ADD artifacts/ibm-ucd-patterns-install /tmp/ibm-ucd-patterns-install
ADD config/opt/startup.sh /opt

EXPOSE 9080
EXPOSE 9443
EXPOSE 22
CMD ["/opt/startup.sh"] 

RUN mkdir /var/run/sshd && \
	chmod 0755 /var/run/sshd && \
	cd /tmp/ibm-ucd-patterns-install/web-install && \
	JAVA_HOME=/tmp/ibm-ucd-patterns-install/web-install/media/server/java/jre \
	JAVA_OPTS="-Dlicense.accepted=Y \
	-Dinstall.server.dir=/opt/ibm-ucd-patterns \
	-Dinstall.server.web.host=WEB_SERVER_HOSTNAME \
	-Dinstall.server.web.https.port=9443 \
	-Dinstall.server.web.port=9080 \
	-Dinstall.server.web.always.secure=N  \
	-Dinstall.server.dir=/opt/ibm-ucd-patterns \
	-Dnon-interactive=true \
	-Dinstall.server.licenseServer.url=$LICENSE_SERVER_URL \
	-Dinstall.server.db.type=postgres \
	-Dinstall.server.db.installSchema=N \
	-Dinstall.server.db.username=ibm_ucdp \
	-Dinstall.server.db.password=passw0rd \
	-Dinstall.server.deployServer.url=DEPLOY_SERVER_URL \
	-Dinstall.server.deployServer.authToken=DEPLOY_SERVER_AUTH_TOKEN \
	-Dinstall.server.discoveryServer.url=$WEB_SERVER_HOSTNAME:7575" \
	./gradlew -sSq install && \
	rm -rf /tmp/ibm-ucd-patterns-install/web-install

ADD config/log4j.properties /opt/ibm-ucd-patterns/conf/server/log4j.properties
ADD config/docker-api-client.properties /opt/ibm-ucd-patterns/conf/server/docker-api-client.properties
ADD config/etc/supervisord.conf /etc/supervisord.conf
ADD config/root/seed.sql /root/seed.sql