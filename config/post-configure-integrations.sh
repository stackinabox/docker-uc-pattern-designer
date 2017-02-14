#!/bin/bash

if [ -n "$KEYSTONE_URL" ]; then

  if [ -z "$ENGINE_HOST" ]; then
    ENGINE_HOST=${WEB_SERVER_HOSTNAME}
  fi

  if [ -z "$KEYSTONE_ADMIN_TENANT" ]; then
    KEYSTONE_ADMIN_TENANT=admin
  fi

  if [ -z "$KEYSTONE_ADMIN_USER" ]; then
    KEYSTONE_ADMIN_USER=admin
  fi

  if [ -z "$KEYSTONE_ADMIN_PASS" ]; then
    KEYSTONE_ADMIN_PASS=labstack
  fi

  if [ -z "$KEYSTONE_USER" ]; then
    KEYSTONE_USER=demo
  fi

  if [ -z "$KEYSTONE_PASS" ]; then
    KEYSTONE_PASS=labstack
  fi

  if [ -z "$KEYSTONE_TENANT" ]; then
    KEYSTONE_TENANT=demo
  fi

  if [ -z "$KEYSTONE_DOMAIN" ]; then
    KEYSTONE_DOMAIN=Default
  fi

  env 
  # add user realm for OpenStack
  osAuthRealm=`curl -u ucdpadmin:ucdpadmin \
     -H 'Content-Type: application/json' \
     -X POST \
     -d "
  {
    \"name\": \"OpenStack\",
    \"loginClassName\": \"com.urbancode.landscape.security.authentication.keystone.KeystoneLoginModule\",
    \"description\": \"\",
    \"allowedAttempts\": null,
    \"property/facingType\": \"PUBLIC\",
    \"properties\": 
    {
      \"url\": \""$KEYSTONE_URL"\",
      \"use-available-orchestration\": \"false\",
      \"overridden-orchestration\": \"http\://"$ENGINE_HOST"\:"$ENGINE_8004_PORT"\",
      \"admin-password\": \""$KEYSTONE_ADMIN_PASS"\",
      \"admin-username\": \""$KEYSTONE_ADMIN_USER"\",
      \"admin-tenant\": \""$KEYSTONE_ADMIN_TENANT"\",
      \"domain\": \""$KEYSTONE_DOMAIN"\",
      \"timeoutMins\": \"60\"
    },
    \"authorizationRealm\": 
    {
      \"properties\": {}
    }
  }
  " \
  http://$WEB_SERVER_HOSTNAME:9080/landscaper/security/authenticationRealm/ | python -c \
"import json; import sys;
data=json.load(sys.stdin); print data['id']"`

  echo "osAuthRealm = $osAuthRealm"

  # test connection to authenticationRealm (import users action will not work until we do this)
  curl -s -u ucdpadmin:ucdpadmin \
     -H 'Content-Type: application/json' \
     -X PUT \
     -d "
  {
    \"name\": \"OpenStack\",
    \"loginClassName\": \"com.urbancode.landscape.security.authentication.keystone.KeystoneLoginModule\",
    \"description\": \"\",
    \"allowedAttempts\": 0,
    \"property/facingType\": \"PUBLIC\",
    \"properties\": 
    {
      \"url\": \""$KEYSTONE_URL"\",
      \"use-available-orchestration\": \"false\",
      \"overridden-orchestration\": \"http\://"$ENGINE_HOST"\:"$ENGINE_8004_PORT"\",
      \"admin-password\": \""$KEYSTONE_ADMIN_PASS"\",
      \"admin-username\": \""$KEYSTONE_ADMIN_USER"\",
      \"admin-tenant\": \""$KEYSTONE_ADMIN_TENANT"\",
      \"domain\": \""$KEYSTONE_DOMAIN"\",
      \"timeoutMins\": \"60\"
    },
    \"authorizationRealm\": 
    {
      \"properties\": {},
      \"existingId\": \""$osAuthRealm"\"
    }
  }
     " \
     http://$WEB_SERVER_HOSTNAME:9080/landscaper/security/authenticationRealm/testConnection

  # import users from new OpenStack user auth realm
  curl -s -u ucdpadmin:ucdpadmin \
     -H 'Content-Type: application/json' \
     -X PUT \
     -d "
  {
    \"name\": \"OpenStack\",
    \"loginClassName\": \"com.urbancode.landscape.security.authentication.keystone.KeystoneLoginModule\",
    \"description\": \"\",
    \"allowedAttempts\": 0,
    \"property/facingType\": \"PUBLIC\",
    \"properties\": 
    {
      \"url\": \""$KEYSTONE_URL"\",
      \"use-available-orchestration\": \"false\",
      \"overridden-orchestration\": \"http\://"$ENGINE_HOST"\:"$ENGINE_8004_PORT"\",
      \"admin-password\": \""$KEYSTONE_ADMIN_PASS"\",
      \"admin-username\": \""$KEYSTONE_ADMIN_USER"\",
      \"admin-tenant\": \""$KEYSTONE_ADMIN_TENANT"\",
      \"domain\": \""$KEYSTONE_DOMAIN"\",
      \"timeoutMins\": \"60\"
    },
    \"authorizationRealm\": 
    {
      \"properties\": {},
      \"existingId\": \""$osAuthRealm"\"
    }
  }
     " \
     http://$WEB_SERVER_HOSTNAME:9080/landscaper/security/authenticationRealm/$osAuthRealm/importUsers/undefined
  
  # find OpenStack cloud provider
  osCloudProvider=`curl -s -u ucdpadmin:ucdpadmin \
     -H 'Content-Type: application/json' \
     -X GET \
     http://$WEB_SERVER_HOSTNAME:9080/landscaper/security/cloudprovider/ | python -c \
"import json; import sys;
data=json.load(sys.stdin);
for item in data:
  if item['name'] == 'OpenStack':
    print item['id']"`

  echo "osCloudProvider = $osCloudProvider"

  # find 'demo' cloud project under the OpenStack cloud provider
  osCloudProject=`curl -s -u ucdpadmin:ucdpadmin \
     -H 'Content-Type: application/json' \
     -X GET \
     http://$WEB_SERVER_HOSTNAME:9080/landscaper/security/cloudprovider/$osCloudProvider/projects | python -c \
"import json; import sys;
data=json.load(sys.stdin);
for item in data:
  if item['name'] == 'demo':
    print item['id']"`

  echo "osCloudProject = $osCloudProject"

  # add cloud authorization credentials to osCloudProject
  curl -s -u ucdpadmin:ucdpadmin \
     -H 'Content-Type: application/json' \
     -X PUT \
     -d "
  {
    \"name\": \"demo\",
    \"cloudProviderId\": \""$osCloudProvider"\",
    \"existingId\": \"$osCloudProject\",
    \"properties\": 
    [
      {
        \"name\": \"functionalId\",
        \"value\": \""$KEYSTONE_USER"\",
        \"secure\": false
      },
      {
        \"name\": \"functionalPassword\",
        \"value\": \""$KEYSTONE_PASS"\",
        \"secure\": true
      },
      {
        \"name\": \"domain\",
        \"value\": \""$KEYSTONE_DOMAIN"\",
        \"secure\": false
      }
    ]
  }
  " \
  http://$WEB_SERVER_HOSTNAME:9080/landscaper/security/cloudproject/osCloudProject

  # lookup keystone_user
  keystoneUser=`curl -s -u ucdpadmin:ucdpadmin \
     -H 'Content-Type: application/json' \
     -X GET \
     http://$WEB_SERVER_HOSTNAME:9080/landscaper/security/user/ | python -c \
"import json; import sys;
data=json.load(sys.stdin);
for item in data:
  if item['name'] == 'demo':
    print item['id']"`

  echo "KeystoneUser = $keystoneUser"

  # create new 'demo' team and map keystone_user into it with appropriate roles
  osDemoTeam=`curl -s -u ucdpadmin:ucdpadmin \
     -H 'Content-Type: application/json' \
     -X POST \
     -d "
  {
    \"name\": \"demo\",
    \"roleMappings\": 
    [
      {
        \"user\": \""$keystoneUser"\",
        \"role\": \"00000000-0000-0000-0000-000000000004\"
      },
      {
        \"user\": \""$keystoneUser"\",
        \"role\": \"00000000-0000-0000-0000-000000000005\"
      },
      {
        \"user\": \""$keystoneUser"\",
        \"role\": \"00000000-0000-0000-0000-000000000301\"
      },
      {
        \"user\": \""$keystoneUser"\",
        \"role\": \"00000000-0000-0000-0000-000000000302\" 
      },
      { 
        \"user\": \""$keystoneUser"\",
        \"role\": \"00000000-0000-0000-0000-000000000303\"
      }
    ],
    \"resources\": [],
    \"cloud_projects\": []
  }
  " \
  http://$WEB_SERVER_HOSTNAME:9080/landscaper/security/team/ | python -c \
"import json; import sys;
data=json.load(sys.stdin); print data['id']"`

  # add osCloudProject as authorized cloud project on this team
  curl -s -u ucdpadmin:ucdpadmin \
     -H 'Content-Type: application/json' \
     -X PUT \
     -d "
  {
    \"name\": \"demo\",
    \"roleMappings\": 
    [
      {
        \"user\": \""$keystoneUser"\",
        \"role\": \"00000000-0000-0000-0000-000000000004\"
      },
      {
        \"user\": \""$keystoneUser"\",
        \"role\": \"00000000-0000-0000-0000-000000000005\"
      },
      {
        \"user\": \""$keystoneUser"\",
        \"role\": \"00000000-0000-0000-0000-000000000301\"
      },
      {
        \"user\": \""$keystoneUser"\",
        \"role\": \"00000000-0000-0000-0000-000000000302\"
      },
      {
        \"user\": \""$keystoneUser"\",
        \"role\": \"00000000-0000-0000-0000-000000000303\"
      }
    ],
    \"resources\": [],
    \"cloud_projects\": [\""$osCloudProject"\"]
  }
  " \
  http://$WEB_SERVER_HOSTNAME:9080/landscaper/security/team/$osDemoTeam
fi 


if [ -n "$DEPLOY_SERVER_HOST" ]; then

  echo "Attempting to register with UrbanCode Deploy server at ${DEPLOY_SERVER_URL}"
  DEPLOY_SERVER_URL="${DEPLOY_SERVER_PROTO}://${DEPLOY_SERVER_HOST}:${DEPLOY_SERVER_PORT}"
  echo "DEPLOY_SERVER_PROTO: ${DEPLOY_SERVER_PROTO}"
  echo "DEPLOY_SERVER_HOST: ${DEPLOY_SERVER_HOST}"
  echo "DEPLOY_SERVER_PORT: ${DEPLOY_SERVER_PORT}"

  cat << EOF > pattern-integration
  {
    "name": "landscaper",
    "description": "",
    "properties": {
      "landscaperUrl": "http\://${WEB_SERVER_HOSTNAME}\:9080/landscaper",
      "landscaperUser": "${KEYSTONE_USER}",
      "landscaperPassword": "${KEYSTONE_PASS}",
      "useAdminCredentials": "true"
    }
  }
EOF
  
  /usr/local/bin/wait-for-it.sh $DEPLOY_SERVER_HOST:$DEPLOY_SERVER_PORT --timeout=0 --strict -- \
  curl -k -s -u admin:admin \
    -H 'Accept: application/json' \
    -X PUT \
    -d @pattern-integration \
    "${DEPLOY_SERVER_URL}/rest/integration/pattern"

else
  echo "TIP: Pass ENV variables at startup via -e DEPLOY_SERVER_HOST=192.168.27.100 [DEPLOY_SERVER_PORT|DEPLOY_SERVER_PROTO] to automatically register it with this patterns container."
fi

exit 0