
-- CHANGE: Update to use the database name that you use in the installation process.

-- INSERT OpenStack Default Realm Authorization --
insert into sec_authorization_realm (id, version, name, description, authorization_module, ghosted_date)
    values ('00000000-0000-0000-0000-000000000002', 0, 'BlueBox Default Realm Authorization', 'BlueBox Default Realm Authorization', 'com.urbancode.landscape.security.authorization.keystone.KeystoneAuthorizationModule', 0);
-- INSERT OpenStack Default Realm Authentication --
insert into sec_authentication_realm (id, version, name, description, sort_order, enabled, read_only, login_module, sec_authorization_realm_id, ghosted_date, allowed_attempts)
    values ('00000000-0000-0000-0000-000000000002', 0, 'BlueBox Default Realm', 'BlueBox Default Realm Authentication Realm', 1, 'Y', 'Y', 'com.urbancode.landscape.security.authentication.keystone.KeystoneLoginModule', '00000000-0000-0000-0000-000000000002', 0, 0);


-- TODO: Update the default user associated with your keystone --
insert into sec_user (id, version, name, enabled, password, actual_name, email, sec_authentication_realm_id, ghosted_date, sec_license_type_id_requested)
    values ('00000000-0000-0000-0000-000000000011', 0, 'admin', 'Y', '', null, 'admin@default', '00000000-0000-0000-0000-000000000002', 0, '00000000-0000-0000-0000-000000000027');

insert into sec_user (id, version, name, enabled, password, actual_name, email, sec_authentication_realm_id, ghosted_date, sec_license_type_id_requested)
    values ('00000000-0000-0000-0000-000000000012', 0, 'demo', 'Y', '', null, 'demo@default', '00000000-0000-0000-0000-000000000002', 0, '00000000-0000-0000-0000-000000000027');

-- INSERT the user into a team with a specific role. --
insert into sec_team_space (id, version, name, description, enabled)
    values ('00000000-0000-0000-0000-000000000207', 0, 'Development', 'Development Team', 'Y');
insert into sec_user_role_on_team (id, version, sec_user_id, sec_role_id, sec_team_space_id)
    values ('00000000-0000-0000-0000-000000001401', 0, '00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000301','00000000-0000-0000-0000-000000000207');
insert into sec_user_role_on_team (id, version, sec_user_id, sec_role_id, sec_team_space_id)
    values ('00000000-0000-0000-0000-000000001402', 0, '00000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000301','00000000-0000-0000-0000-000000000207');
    
-- TODO: Replace all parameter values with tokens, and substitute them when the component process runs
-- TODO: Update the URL to match your OpenStack Keystone API access point --
insert into sec_authentication_realm_prop (sec_authentication_realm_id, name, value)
    values ('00000000-0000-0000-0000-000000000002', 'url', 'http://KEYSTONE_HOSTNAME:5000/v2.0');

insert into sec_authentication_realm_prop (sec_authentication_realm_id, name, value) 
	values ('00000000-0000-0000-0000-000000000002', 'admin-username', 'admin');
insert into sec_authentication_realm_prop (sec_authentication_realm_id, name, value) 
	values ('00000000-0000-0000-0000-000000000002', 'admin-password', 'labstack');
insert into sec_authentication_realm_prop (sec_authentication_realm_id, name, value) 
	values ('00000000-0000-0000-0000-000000000002', 'admin-tenant', 'admin');
insert into sec_authentication_realm_prop (sec_authentication_realm_id, name, value) 
	values ('00000000-0000-0000-0000-000000000002', 'use-available-orchestration', 'false');
insert into sec_authentication_realm_prop (sec_authentication_realm_id, name, value)
    values ('00000000-0000-0000-0000-000000000002', 'overridden-orchestration', 'http://ENGINE_ENV_PUBLIC_HOSTNAME:ENGINE_PORT_8004_TCP_PORT'); --
insert into sec_authentication_realm_prop (sec_authentication_realm_id, name, value) 
	values ('00000000-0000-0000-0000-000000000002', 'timeoutMins', 10);
insert into sec_authentication_realm_prop (sec_authentication_realm_id, name, value) 
	values ('00000000-0000-0000-0000-000000000002', 'automated_post_install_config_version', 2);
	
	
insert into ps_prop_sheet (id, version, name, prop_sheet_group_id, prop_sheet_def_id, prop_sheet_def_handle, template_prop_sheet_id, template_handle)
	values ('00000000-0000-0000-9999-000000000004',0,NULL,NULL,NULL,NULL,NULL,NULL), ('00000000-0000-0000-9999-000000000002',0,NULL,NULL,NULL,NULL,NULL,NULL);
insert into ls_cloud_provider (id, version, date_created, name, description, provider_type, prop_sheet_id)
	values ('00000000-0000-0000-9999-000000000001',0,1407515057046,'BlueBox','', 'AUTH_REALM','00000000-0000-0000-9999-000000000002');
insert into ls_cloud_project (id, version, date_created, name, description, cloud_provider_id, prop_sheet_id, project_type)
	values ('00000000-0000-0000-9999-000000000003',0,1407515057370,'demo','','00000000-0000-0000-9999-000000000001','00000000-0000-0000-9999-000000000004','AUTH_REALM');
insert into ls_cloud_project_for_team (id, version, date_created, ls_cloud_project_id, sec_team_space_id)
	values ('00000000-0000-0000-9999-000000000006',0,1407515058518,'00000000-0000-0000-9999-000000000003','00000000-0000-0000-0000-000000000207');
insert into ps_prop_value (id, version, name, value, long_value, label, long_label, description, secure, prop_sheet_id) 
    values  ('00000000-0000-0000-9999-000000000007',0,'authentication_realm_id','00000000-0000-0000-0000-000000000002',NULL,'',NULL,NULL,'N','00000000-0000-0000-9999-000000000002'), ('00000000-0000-0000-9999-000000000009',0,'functionalPassword','pbe{GFqHYtd0CGM4VYBpt3P7dANZv3rF06ML}',NULL,'',NULL,NULL,'Y','00000000-0000-0000-9999-000000000004'), ('00000000-0000-0000-9999-000000000010',0,'functionalId','demo',NULL,'',NULL,NULL,'N','00000000-0000-0000-9999-000000000004');		
		
    
-- delete from sec_user_role_on_team where id='00000000-0000-0000-0000-000000001401';
-- delete from sec_user_role_on_team where id='00000000-0000-0000-0000-000000001402';
-- delete from sec_team_space where id='00000000-0000-0000-0000-000000000207';
-- delete from sec_user where id='00000000-0000-0000-0000-000000000011';
-- delete from sec_user where id='00000000-0000-0000-0000-000000000012';
-- delete from sec_authentication_realm_prop where sec_authentication_realm_id='00000000-0000-0000-0000-000000000002';
-- delete from sec_authentication_realm where id='00000000-0000-0000-0000-000000000002';
-- delete from sec_authorization_realm where id='00000000-0000-0000-0000-000000000002';