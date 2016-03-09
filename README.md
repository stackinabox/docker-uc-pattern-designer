## docker-uc-pattern-designer
Builds Docker image for UrbanCode Deploy Blueprint Designer (visual HEAT editor)

Depends on ubuntu:14.04

To run:

# assuming /etc/hosts looks like 
# 192.168.99.100 	docker
# 192.168.27.100    devstack

# log into registry.oneibmcloud.com
docker login registry.oneibmcloud.com

# run UCD
docker run -d --name urbancode_deploy -e LICENSE=accept -p 7918:7918 -p 8080:8080 -p 8443:8443 stackinabox/urbancode-deploy:6.2.0.2.723274

# add this option to below line when connection to external keystone -e ALLOWED_AUTH_URIS=http://devstack:5000/v2.0
docker run -d --name urbancode_patterns_engine -e PUBLIC_HOSTNAME=docker -e ENGINE_HOSTNAME=docker -p 8000:8000 -p 8003:8003 -p 8004:8004 stackinabox/urbancode-patterns-engine:6.2.1.0.742246

# run postgres first then link designer to postgres container
docker run -d --name patterns_db -e POSTGRES_PASSWORD=aWJtX3VjZHAK -e POSTGRES_USER=ibm_ucdp -e POSTGRES_DATABASE=ibm_ucdp postgres

docker run -d --name urbancode_patterns_designer --link patterns_db:database --link urbancode_deploy:deploy --link urbancode_patterns_engine:engine -e WEB_SERVER_HOSTNAME=docker -e KEYSTONE_URL=docker -p 9080:9080 -p 9443:9443 -p 7575:7575 stackinabox/urbancode-patterns-designer:6.2.1.0.753591
