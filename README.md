## docker-uc-pattern-designer
Builds Docker image for UrbanCode Deploy Blueprint Designer (visual HEAT editor)

To run:

 - docker pull ubuntu:14.04

 - git clone https://github.com/stackinabox/docker-uc-patterns-designer.git

 - Download UCD with Patterns Web Designer installer zip and extract it into 'artifacts' folder
   You are on your own for finding this since it's a licensed product

 - Build the image:

 ````
     docker build -t stackinabox/urbancode-patterns-designer:%version% .
 ````

  - Before you can run it you'll need to pull the postgre image into your local docker repo:

 ````
    docker pull postgre
 ````

  - The the patterns-engine image relies on a postgre sql image for it's database
    you'll need to create a new container from the postgre image like so:

 ````
    docker run -d --name patterns_db -e POSTGRES_PASSWORD=aWJtX3VjZHAK -e POSTGRES_USER=ibm_ucdp -e POSTGRES_DATABASE=ibm_ucdp postgres
 ````

 - Now you can run the image:
   Let me explain what all of these links and ENV properties are that I'm passing into the run command

   - link patterns_db:database
     - __patterns_db__ is the name of the of the container that is running the postgre database image
     - __database__ is the name of the link that the container expects to find (so don't change the name)

   - link urbancode_patterns_engine:engine
     - __urbancode_patterns_engine__ the container running the stackinabox/urbancode-patterns-engine
     - __engine__ is the name of the link that the container expects to find (so don't change the name)

   - link urbancode_deploy:deploy (handles configuring ucd and ucdp comunication)
     - __urbancode_deploy__ is the name of the container running the stackinabox/urbancode-deploy image
     - __deploy__ is the name of the link that the container expects to find (so don't change the name)

   - WEB_SERVER_HOSTNAME: is the dns resolvable hostname for this container
   - KEYSTONE_URL: the ip address or hostname of the Keystone server to be connected to the ucd w/ patterns server


````
   docker run -d --name urbancode_patterns_designer --link patterns_db:database --link urbancode_patterns_engine:engine --link urbancode_deploy:deploy -e WEB_SERVER_HOSTNAME=docker -e KEYSTONE_URL=192.168.27.100 -p 9080:9080 -p 9443:9443 -p 7575:7575 stackinabox/urbancode-patterns-designer:%version%
````

 - You should now be able to open your browser to https://WEB_SERVER_HOSTNAME:8443/landscaper and login with ucdpadmin:ucdpadmin or user:user

