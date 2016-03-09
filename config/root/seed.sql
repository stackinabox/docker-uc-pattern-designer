

-- ls_cloud_provider (
--  id varchar(36) NOT NULL,
--  version int(11) NOT NULL DEFAULT '0',
--  date_created bigint(20) NOT NULL,
--  name varchar(255) NOT NULL,
--  description varchar(4000) DEFAULT NULL,
--  provider_type varchar(255) NOT NULL,
--  prop_sheet_id varchar(36) DEFAULT NULL,
--  cost_center_id varchar(36) DEFAULT NULL,
--  PRIMARY KEY (id)

INSERT INTO ls_cloud_provider 
  VALUES ('694e862f-7aa7-4d34-9388-a9ac377001da',0,1431863211720,'BlueBox Identity Service',
          '','OPENSTACK','38d0a5ff-89bd-4574-bfc2-884edbf6a90a',NULL);

INSERT INTO ps_prop_sheet 
  VALUES   ('38d0a5ff-89bd-4574-bfc2-884edbf6a90a',1,NULL,NULL,NULL,NULL,NULL,NULL);

INSERT INTO ps_prop_value 
  VALUES ('11db0b5a-5751-4779-bfd6-aa07c7e3eb10',0,
          'timeoutMins','60',NULL,'',NULL,NULL,
          'N','38d0a5ff-89bd-4574-bfc2-884edbf6a90a'),
         ('169d2e4f-86bc-43ed-b8bd-c1fa8f697026',0,
          'orchestrationEngineUrl','http://ENGINE_ENV_PUBLIC_HOSTNAME:ENGINE_PORT_8004_TCP_PORT',NULL,'',NULL,NULL,
          'N','38d0a5ff-89bd-4574-bfc2-884edbf6a90a'),
         ('8550d19a-e852-4737-a6e0-25f8bd1f85ea',0,
          'url','http://KEYSTONE_URL:ENGINE_PORT_5000_TCP_PORT/v2.0',NULL,'',NULL,NULL,
          'N','38d0a5ff-89bd-4574-bfc2-884edbf6a90a'),
         ('f31b2b2c-5d0d-44a4-88f3-4059cca763d5',0,
          'useDefaultOrchestration','false',NULL,'',NULL,NULL,
          'N','38d0a5ff-89bd-4574-bfc2-884edbf6a90a');
  
-- ls_cloud_project (
--  id varchar(36) NOT NULL,
--  version int(11) NOT NULL DEFAULT '0',
--  date_created bigint(20) NOT NULL,
--  name varchar(255) NOT NULL,
--  description varchar(4000) DEFAULT NULL,
--  cloud_provider_id varchar(36) NOT NULL,
--  prop_sheet_id varchar(36) DEFAULT NULL,
--  project_type varchar(255) NOT NULL,
--  PRIMARY KEY (id)
  


INSERT INTO ls_cloud_project 
  VALUES ('c2a41223-d0bc-4a24-b967-64f7997a2ca1',0,1431863217701,'demo','',
          '694e862f-7aa7-4d34-9388-a9ac377001da','768686f8-3683-4576-bd04-27d57f84b82c',
          'OPENSTACK');

INSERT INTO ps_prop_sheet 
  VALUES ('768686f8-3683-4576-bd04-27d57f84b82c',0,NULL,NULL,NULL,NULL,NULL,NULL);

INSERT INTO ps_prop_value 
  VALUES ('237be3d2-ed6f-4062-98bc-5e6d71b7b258',0,
          'functionalId','demo',NULL,'',NULL,NULL,
          'N','768686f8-3683-4576-bd04-27d57f84b82c'),  
         ('f51fe9d3-c914-4781-b953-90207348b0bf',0,
          'functionalPassword','pbe{/md4XHBzwkscaUJZOl8RSsIYGWUzNpIbrt0fSnYUKso=}',NULL,'',NULL,NULL,
          'Y','768686f8-3683-4576-bd04-27d57f84b82c');


-- ls_cloud_project_for_team (
--  id varchar(36) NOT NULL,
--  version int(11) NOT NULL DEFAULT '0',
--  date_created bigint(20) NOT NULL,
--  ls_cloud_project_id varchar(36) NOT NULL,
-- sec_team_space_id varchar(36) NOT NULL,
--  PRIMARY KEY (id)  
INSERT INTO ls_cloud_project_for_team 
  VALUES ('ba8c2972-48d7-40b5-a220-f985fd93a8cc',
           0,1431863576850,'c2a41223-d0bc-4a24-b967-64f7997a2ca1',
           '00000000-0000-0000-0000-000000000206');
