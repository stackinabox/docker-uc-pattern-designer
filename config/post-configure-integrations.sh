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

  env
  # import users from new OpenStack user auth realm
  curl -s -u ucdpadmin:ucdpadmin \
     -H 'Content-Type: application/json' \
     -X PUT \
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

  env
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

  env
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

  env
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

if [ -n "$DEPLOY_SERVER_URL" ]; then

  echo "attempting to register blueprintdesiger with UCD server at ${DEPLOY_SERVER_URL}"
  # UCD Server takes a few seconds to startup. If we call this function too early it will fail
  # loop until it succeeds or fail after # of attempts
  attempt=1
  until $(curl -k -u admin:admin --output /dev/null --silent --head --fail "${DEPLOY_SERVER_URL}/cli/systemConfiguration"); do
      attempt=$(($attempt + 1))
      sleep 10
      if [ "$attempt" -gt "18" ]; then
        echo "Failed to connect to ${DEPLOY_SERVER_URL}. Please check url for valid server and try again."
        exit 1
      fi
  done

  echo "verified connectivity to UCD server at ${DEPLOY_SERVER_URL}"
  
  if [ -z "$DEPLOY_SERVER_AUTH_TOKEN" ]; then
  
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

  curl -k -s -u admin:admin \
    -H 'Accept: application/json' \
    -X PUT \
    -d @pattern-integration \
    "${DEPLOY_SERVER_URL}/rest/integration/pattern"


else
  echo "TIP: Pass ENV variable at startup via -e DEPLOY_SERVER_URL=http://192.168.27.100:8080 to automatically register it with this patterns container."
fi

exit 0