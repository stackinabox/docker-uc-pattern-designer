#!/bin/sh

export PGPASSWORD=$DATABASE_ENV_POSTGRES_PASSWORD
DEFAULT_REALM_ID=`psql -h $DATABASE_PORT_5432_TCP_ADDR -p $DATABASE_PORT_5432_TCP_PORT $DATABASE_ENV_POSTGRES_DATABASE -U $DATABASE_ENV_POSTGRES_USER -c "select id from sec_authorization_realm where name='OpenStack Default Realm Authorization'"`
CURRENT_AUTO_CONFIG_VERSION=`psql -h $DATABASE_PORT_5432_TCP_ADDR -p $DATABASE_PORT_5432_TCP_PORT $DATABASE_ENV_POSTGRES_DATABASE -U $DATABASE_ENV_POSTGRES_USER -c "select value from sec_authentication_realm_prop where name='automated_post_install_config_version'"`
CURRENT_AUTO_CONFIG_VERSION=`echo $CURRENT_AUTO_CONFIG_VERSION | cut -d " " -f 2`



echo "Current Default Realm ID: \"$DEFAULT_REALM_ID\""
echo "Current post-config properties for version $CURRENT_AUTO_CONFIG_VERSION already installed. Skipping post-config database update."

if [ -z "$DEFAULT_REALM_ID" ];  then
  echo "-- Configuring the default OpenStack Default Realm Authorization..."
  psql -h $DATABASE_PORT_5432_TCP_ADDR -p $DATABASE_PORT_5432_TCP_PORT $DATABASE_ENV_POSTGRES_DATABASE -U $DATABASE_ENV_POSTGRES_USER -f post_install_config.sql
else
  echo "-- Skipping configuration for default OpenStack Default Realm Authorization"
fi

