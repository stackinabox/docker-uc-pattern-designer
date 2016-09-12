#!/bin/bash
set -e

IFC=$(ifconfig | grep '^[a-z0-9]' | awk '{print $1}' | grep -e ns -e eth0)
IP_ADDRESS=$(ifconfig $IFC | grep 'inet addr' | awk -F : {'print $2'} | awk {'print $1'})
echo "This node has an IP of " $IP_ADDRESS

env

if [ -z "$DATABASE_HOST" ]; then
  echo "Please start this container with a Postgres database using '-e DATABASE_HOST=192.168.27.xxx'"
  exit 1
fi

if [ -z "$DATABASE_NAME" ]; then
  DATABASE_NAME=ibm_ucdp
fi

if [ -z "$DATABASE_PORT" ]; then
  DATABASE_PORT=5432
fi

if [ -z "DOCKER_HOST" ]; then
  DOCKER_HOST=localhost
fi

if [ -z "DOCKER_PORT" ]; then
  DOCKER_HOST=2375
fi

# Escape characters which might confuse the regex in sed below
DATABASE_CONNECTION_URL=`echo "jdbc\:postgresql\://${DATABASE_HOST}\:${DATABASE_PORT}/${DATABASE_NAME}" | sed -e 's/[]\/$*.^|[]/\\\\&/g'`
sed -i "s/\(hibernate\.connection\.url=\).*\$/\1${DATABASE_CONNECTION_URL}/" /opt/ibm-ucd-patterns/conf/server/server.properties

if [ -n $DATABASE_USER ]; then
  sed -i "s/\(hibernate\.connection\.username=\).*\$/\1${DATABASE_USER}/" /opt/ibm-ucd-patterns/conf/server/server.properties
fi

if [ -n $DATABASE_PASS ]; then
  sed -i "s/\(hibernate\.connection\.password=\).*\$/\1${DATABASE_PASS}/" /opt/ibm-ucd-patterns/conf/server/server.properties
fi

sed -i "s/\(install\.server\.web\.host=\).*\$/\1${WEB_SERVER_HOSTNAME}/" /opt/ibm-ucd-patterns/conf/server/server.properties

PUBLIC_URL=`echo "http\://${WEB_SERVER_HOSTNAME}\:9080/landscaper" | sed -e 's/[]\/$*.^|[]/\\\\&/g'`
sed -i "s/\(public\.url=\).*\$/\1${PUBLIC_URL}/" /opt/ibm-ucd-patterns/conf/server/server.properties

# Gitblit url 
GITBLIT_URL=`echo "http\://${WEB_SERVER_HOSTNAME}\:9080/gitblit" | sed -e 's/[]\/$*.^|[]/\\\\&/g'`
sed -i "s/\(com\.ibm\.landscaper\.gitblit\.url=\).*\$/\1${GITBLIT_URL}/" /opt/ibm-ucd-patterns/conf/server/server.properties


# Using insecure connection for now for filesystem
VERSIONED_FILESYSTEM_API_URL=`echo "http\://${WEB_SERVER_HOSTNAME}\:9080/landscaper" | sed -e 's/[]\/$*.^|[]/\\\\&/g'`
sed -i "s/\(versioned-filesystem-client\.ribbon\.listOfServers=\).*\$/\1${VERSIONED_FILESYSTEM_API_URL}/" /opt/ibm-ucd-patterns/conf/server/versioned-filesystem-client.properties

sed -i "s/WEB_SERVER_HOSTNAME/${WEB_SERVER_HOSTNAME}/" /opt/ibm-ucd-patterns/conf/server/engine-services-client.properties
sed -i "s/WEB_SERVER_HOSTNAME/${WEB_SERVER_HOSTNAME}/" /opt/ibm-ucd-patterns/conf/server/server.properties

if [ -n "$DOCKER_HOST" ]; then
  if [ -z "$DOCKER_PORT" ]; then
    DOCKER_PORT=2376
  fi

  sed -i "s/DOCKER_REMOTE_URL/${DOCKER_HOST}\:${DOCKER_PORT}/" /opt/ibm-ucd-patterns/conf/server/docker-api-client.properties

  if [ -z "$DOCKER_PROTO" ]; then
    DOCKER_PROTO="https"
  fi
  echo "com.ibm.patterns.docker.remote.url=${DOCKER_PROTO}\://${DOCKER_HOST}\:${DOCKER_PORT}" >> /opt/ibm-ucd-patterns/conf/server/config.properties
else
  # Delete value
  echo "TIP: You can associate this container with a Docker Remote API endpoint to enable Heat-based multiple-node docker designs in the editor."
  echo "TIP: To enable the integration add -e DOCKER_HOST={docker host} [-e DOCKER_PORT={2376 by default}] [-e DOCKER_PROTO={https by default}]"
  sed -i "s/DOCKER_REMOTE_URL//" /opt/ibm-ucd-patterns/conf/server/docker-api-client.properties
fi

if [ -n "$ENGINE_HOST" ]; then
  echo "$ENGINE_HOST $ENGINE_HOST" >> /etc/hosts

  # linked to an engine, configure appropriately
  sed -i "s/ENGINE_ENV_PUBLIC_HOSTNAME/${ENGINE_HOST}/" /root/seed.sql
  sed -i "s/ENGINE_PORT_8004_TCP_PORT/${ENGINE_8004_PORT}/" /root/seed.sql
  sed -i "s/ENGINE_PORT_5000_TCP_PORT/${ENGINE_5000_PORT}/" /root/seed.sql

  sed -i "s|KEYSTONE_URL|${KEYSTONE_URL}|g" /root/seed.sql

  DATABASE_SEED_DATA_DIR="/opt/ibm-ucd-patterns/opt/tomcat/webapps/landscaper/WEB-INF/database/translations"
  DATABASE_LOCALE="en_us"
  DATABASE_SEED_DATA_FILE="${DATABASE_SEED_DATA_DIR}/${DATABASE_LOCALE}/ur-seed-data.sql"

  echo "INFO: Defaulting to US English Locale (en_us). If this is the wrong locale,
       some information may not be pre-populated in your designer."
  if [ -f "$DATABASE_SEED_DATA_FILE" ]; then
    echo "Updating default seed data with linked container information for the ENGINE."
    cat /root/seed.sql >> $DATABASE_SEED_DATA_FILE
    echo "UPDATED FILE within container: " $DATABASE_SEED_DATA_FILE
 else
    echo "ERROR: The default seed data file was not found within the container:"
    echo ""
    echo "MISSING FILE within container: $DATABASE_SEED_DATA_FILE"

    echo "Configure the default engine using the following command:
      psql -u $DATABASE_USER -p$DATABASE_PASS \
        -D$DATABASE_NAME -h $ENGINE_ENV_PUBLIC_HOSTNAME\
        -P $DATABASE_PORT -f seed.sql"
    echo "Use the following seed.sql:"
    cat /root/seed.sql
  fi
else
  echo "WARN: Either no engine was linked, or the engine did not specify an alias for its PUBLIC_HOSTNAME."
  echo "TIP: When you launch the engine container, use '-e PUBLIC_HOSTNAME={host alias}' "
  echo "     where the host alias may be 'boot2docker' or a user defined host alias defined in your /etc/hosts."
fi

if [ -n "$DEPLOY_SERVER_URL" ]; then

  if [ -z "$DEPLOY_SERVER_AUTH_TOKEN" ]; then

    # UCD Server takes a few seconds to startup. If we call this function too early it will fail
    # loop until it succeeds or fail after # of attempts
    attempt=1
    until [ -n "$DEPLOY_SERVER_AUTH_TOKEN" ]; do
      attempt=$(($attempt + 1))
      sleep 10

      echo "Attempting to automatically integrate blueprint designer with UCD server ${DEPLOY_SERVER_URL}. Requesting auth token on UCD server... $attempt"
      DEPLOY_SERVER_AUTH_TOKEN=$(curl -k -u admin:admin \
        -X PUT \
        "${DEPLOY_SERVER_URL}/cli/teamsecurity/tokens?user=admin&expireDate=12-31-2020-12:00" | python -c \
"import json; import sys;
data=json.load(sys.stdin);
print data['token']")

      if [ "$attempt" -gt "18" ]; then
        echo "Failed to request auth token on UCD server ${DEPLOY_SERVER_URL}. Unable to automatically integrate blueprintdesiger with UCD server."
        exit 1
      fi
    done
  fi

  echo "Registering UrbanCode Deploy server: "
  echo "DEPLOY_SERVER_URL=${DEPLOY_SERVER_URL}"
  echo "DEPLOY_SERVER_AUTH_TOKEN=${DEPLOY_SERVER_AUTH_TOKEN}"
  
  sed -i "s|DEPLOY_SERVER_URL|${DEPLOY_SERVER_URL}|g" /opt/ibm-ucd-patterns/conf/server/config.properties
  sed -i "s|DEPLOY_SERVER_AUTH_TOKEN|${DEPLOY_SERVER_AUTH_TOKEN}|g" /opt/ibm-ucd-patterns/conf/server/config.properties
  
fi

if [ -n "$LOG_CONFIG" ]; then
  CONFIG_DIR=/opt/ibm-ucd-patterns/conf/server
  for log in `ls $CONFIG_DIR/*.properties`; do

    echo "************************************************************************"
    echo "BEGIN CONFIG FILE: $log"
    echo "************************************************************************"
    cat "$log"
    echo "" # Ensure that a line break occurs before the suffix text
    echo "************************************************************************"
    echo "END CONFIG FILE: $log"
    echo "************************************************************************"
  done
fi

/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
