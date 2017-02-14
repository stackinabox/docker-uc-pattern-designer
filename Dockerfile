FROM stackinabox/ibm-supervisord:3.2.2

MAINTAINER Tim Pouyer <tpouyer@us.ibm.com>

# Pass in the location of the UCD agent install zip 
ARG ARTIFACT_DOWNLOAD_URL 
ARG ARTIFACT_VERSION

# Add startup.sh script and addtional supervisord config
ADD startup.sh /opt/startup.sh
ADD supervisord.conf /tmp/supervisord.conf

# ADD wait-for-it.sh script
ADD wait-for-it.sh /usr/local/bin

# Expose Ports
EXPOSE 7575
EXPOSE 9080
EXPOSE 9443

ENV LICENSE_SERVER_URL=${LICENSE_SERVER_URL:-} \
	WEB_SERVER_HOSTNAME=${WEB_SERVER_HOSTNAME:-$HOSTNAME} \
	DATABASE_HOST=${DATABASE_HOST:-} \
	DATABASE_PORT=${DATABASE_PORT:-} \
	DATABASE_NAME=${DATABASE_NAME:-} \
	DATABASE_USER=${DATABASE_USER:-} \
	DATABASE_PASS=${DATABASE_PASS:-} \
	ENGINE_HOST=${ENGINE_HOST:-} \
	ENGINE_5000_PORT=${ENGINE_5000_PORT:-5000} \
	ENGINE_8004_PORT=${ENGINE_8004_PORT:-8004} \
	KEYSTONE_URL=${KEYSTONE_URL:-} \
    KEYSTONE_ADMIN_USER=${KEYSTONE_ADMIN_USER:-admin} \ 
    KEYSTONE_ADMIN_PASS=${KEYSTONE_ADMIN_PASS:-labstack} \
    KEYSTONE_ADMIN_TENANT=${KEYSTONE_ADMIN_TENANT:-admin} \ 
    KEYSTONE_USER=${KEYSTONE_USER:-demo} \ 
    KEYSTONE_PASS=${KEYSTONE_PASS:-labstack} \
    KEYSTONE_TENANT=${KEYSTONE_TENANT:-demo} \ 
    KEYSTONE_DOMAIN=${KEYSTONE_DOMAIN:-Default} \
	DEPLOY_SERVER_HOST=${DEPLOY_SERVER_HOST:-} \
	DEPLOY_SERVER_PORT=${DEPLOY_SERVER_PORT:-8080} \
	DEPLOY_SERVER_PROTO=${DEPLOY_SERVER_PROTO:-http} \
	DEPLOY_SERVER_URL=${DEPLOY_SERVER_URL:-} \
	DEPLOY_SERVER_AUTH_TOKEN=${DEPLOY_SERVER_AUTH_TOKEN:-} \
	DOCKER_HOST=${DOCKER_HOST:-} \
	DOCKER_PORT=${DOCKER_PORT:-2376} \
	DOCKER_PROTO=${DOCKER_PROTO:-https}

RUN apt-get -qqy update && \
	apt-get -qqy install --no-install-recommends build-essential python-setuptools python-pip python-dev git logrotate postgresql-client-* && \
	pip install --upgrade --force-reinstall pbr && \
	pip install --upgrade --force-reinstall pip && \
	export PATH=/usr/local/bin:$PATH && \
	pip install --upgrade --force-reinstall virtualenv && \
	pip install --upgrade --force-reinstall greenlet && \
	wget -q -O - $ARTIFACT_DOWNLOAD_URL | tar zxf - -C /tmp/ && \
	cd /tmp/ibm-ucd-patterns-install/web-install && \
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
	-Dinstall.server.discoveryServer.url=http\://WEB_SERVER_HOSTNAME:7575" \
	./gradlew -sSq install && \
	bash /tmp/ibm-ucd-patterns-install/web-install/media/server/bin/install-cloud-discovery-service.sh && \
	cat /tmp/supervisord.conf >> /etc/supervisor/conf.d/supervisord.conf && \
	apt-get remove -qqy build-essential && \
	apt-get clean -y && \
	apt-get autoclean -y && \
	apt-get autoremove -y && \
	rm -rf /tmp/ibm-ucd-patterns-install /tmp/supervisord.conf /var/lib/apt/lists/*

# Copy in installation properties
ADD config/log4j.properties /opt/ibm-ucd-patterns/conf/server/log4j.properties
ADD config/docker-api-client.properties /opt/ibm-ucd-patterns/conf/server/docker-api-client.properties
ADD config/seed.sql /root/seed.sql
ADD config/post-configure-integrations.sh /root/post-configure-integrations.sh

ENTRYPOINT ["/opt/startup.sh"]
CMD []
