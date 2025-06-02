/* roles */
    -- svc_admin
CREATE ROLE svc_admin
WITH LOGIN
  NOSUPERUSER
  NOINHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  PASSWORD 'svc_admin_125634'
  CONNECTION LIMIT 5;
    -- svc_app
CREATE ROLE svc_app
WITH LOGIN PASSWORD 'svc_app_password';
    -- svc_mod
CREATE ROLE svc_mod NOLOGIN;
CREATE ROLE app_mod_usr
WITH LOGIN PASSWORD 'svc_mod_usr_125634'
INHERIT CONNECTION LIMIT 30;
    -- svc_user
CREATE ROLE svc_user NOLOGIN;
CREATE ROLE app_end_usr
WITH LOGIN PASSWORD 'svc_end_usr_125634'
INHERIT CONNECTION LIMIT 500;

/* db and schema */
    -- db
CREATE DATABASE freelance_app
WITH OWNER = svc_admin 
ENCODING = 'UTF8' 
TEMPLATE = template0;
    -- schema
CREATE SCHEMA core AUTHORIZATION svc_admin;
ALTER ROLE svc_admin SET search_path = core;
ALTER ROLE svc_app SET search_path = core;
ALTER ROLE app_mod_usr SET search_path = core;
ALTER ROLE app_end_usr SET search_path = core;

/* revokes and grants */
REVOKE ALL ON SCHEMA core FROM PUBLIC;
REVOKE ALL ON SCHEMA core FROM svc_app, svc_mod, svc_user, app_mod_usr, app_end_usr;
    -- grants svc_app
GRANT CONNECT ON DATABASE freelance_app TO svc_app;
GRANT USAGE ON SCHEMA core TO svc_app;
GRANT SELECT ON CORE.USERS TO SVC_APP;
GRANT SELECT ON CORE.ROLES TO SVC_APP;
GRANT INSERT ON CORE.USERS TO SVC_APP;
GRANT USAGE, SELECT ON SEQUENCE core.users_id_user_seq TO SVC_APP;
    -- groups roles
GRANT svc_mod TO app_mod_usr;
GRANT svc_user TO app_end_usr;

-- ============================
-- grants svc_admin
-- ============================
GRANT CONNECT, TEMPORARY ON DATABASE freelance_app TO svc_admin;
GRANT USAGE, CREATE ON SCHEMA core TO svc_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA core TO svc_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA core TO svc_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA core TO svc_admin;
GRANT ALL PRIVILEGES ON ALL PROCEDURES IN SCHEMA core TO svc_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT ALL ON TABLES TO svc_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT ALL ON SEQUENCES TO svc_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT ALL ON FUNCTIONS TO svc_admin;
    -- revoke connections to system dbs
REVOKE CONNECT ON DATABASE postgres    FROM svc_admin;
REVOKE CONNECT ON DATABASE template1   FROM svc_admin;
REVOKE CONNECT ON DATABASE template0   FROM svc_admin;

-- ============================
-- grants svc_mod
-- ============================
GRANT CONNECT ON DATABASE freelance_app TO svc_mod;
GRANT USAGE ON SCHEMA core TO svc_mod;
GRANT EXECUTE ON FUNCTION core.mod_get_complaints(text) TO svc_mod;
GRANT EXECUTE ON PROCEDURE core.mod_update_complaint_status(INTEGER, INTEGER, VARCHAR, INTEGER) TO svc_mod;
GRANT EXECUTE ON PROCEDURE core.mod_resolve_complaint(integer, integer, varchar, integer) TO svc_mod;
GRANT EXECUTE ON PROCEDURE core.mod_issue_warning(INT,INT,INT,TEXT,INT) TO svc_mod;
GRANT EXECUTE ON PROCEDURE core.update_user_last_online(integer) TO svc_mod;
    -- views
GRANT SELECT ON core.v_roles TO svc_mod;
GRANT SELECT ON core.v_users TO svc_mod;
GRANT SELECT ON core.v_projects TO svc_mod;
GRANT SELECT ON core.v_reviews TO svc_mod;
GRANT SELECT ON core.v_orders TO svc_mod;
GRANT SELECT ON core.v_order_extended TO svc_mod;
GRANT SELECT ON core.v_order_archive_extended TO svc_mod;
GRANT SELECT ON core.v_portfolio TO svc_mod;
GRANT SELECT ON core.v_mod_users TO svc_mod;
GRANT SELECT ON core.v_mod_complaints TO svc_mod;

-- ============================
-- grants svc_user
-- ============================
GRANT CONNECT ON DATABASE freelance_app TO svc_user;
GRANT USAGE ON SCHEMA core TO svc_user;
GRANT EXECUTE ON FUNCTION core.user_get_users() TO svc_user;
GRANT EXECUTE ON PROCEDURE core.user_update_profile (integer, integer, CHAR(128), VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO svc_user;
GRANT EXECUTE ON PROCEDURE core.user_update_profile (integer, integer, CHAR(128), VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, BYTEA) TO svc_user;
GRANT EXECUTE ON PROCEDURE core.update_user_last_online(integer) TO svc_user;
    -- views
GRANT SELECT ON core.v_roles TO svc_user;
GRANT SELECT ON core.v_users TO svc_user;

GRANT SELECT ON core.v_projects TO svc_user;

GRANT SELECT ON core.v_complaints TO svc_user;
GRANT SELECT ON core.v_all_counterparts TO svc_user;

GRANT SELECT ON core.v_reviews TO svc_user;
GRANT SELECT ON core.v_orders_reviews TO svc_user;

GRANT SELECT ON core.v_orders TO svc_user;
GRANT SELECT ON core.v_order_extended TO svc_user;

GRANT SELECT ON core.v_orders_archive TO svc_user;
GRANT SELECT ON core.v_order_archive_extended TO svc_user;

GRANT SELECT ON core.v_portfolio TO svc_user;

GRANT SELECT ON core.v_user_notifications TO svc_user;

GRANT SELECT ON core.v_user_warnings TO svc_user;

    -- projects
GRANT EXECUTE ON PROCEDURE core.user_create_project TO svc_user;
GRANT EXECUTE ON PROCEDURE core.user_update_project TO svc_user;
GRANT EXECUTE ON PROCEDURE core.user_delete_project(integer) TO svc_user;
GRANT EXECUTE ON FUNCTION core.user_get_projects_by_customer(integer) TO svc_user;
GRANT EXECUTE ON FUNCTION core.user_get_projects() TO svc_user;
GRANT EXECUTE ON FUNCTION core.user_get_projects_by_status(varchar(50)) TO svc_user;
GRANT EXECUTE ON FUNCTION core.user_get_project_by_id(integer) TO svc_user;
    -- orders
GRANT EXECUTE ON PROCEDURE core.user_create_order(integer, integer, varchar, date) TO svc_user;
GRANT EXECUTE ON PROCEDURE core.user_update_order(integer, varchar, date) TO svc_user;
GRANT EXECUTE ON PROCEDURE core.user_delete_order(integer) TO svc_user;
GRANT EXECUTE ON PROCEDURE core.user_archive_order(int) TO svc_user;
GRANT EXECUTE ON FUNCTION core.user_get_orders_by_customer(integer) TO svc_user;
GRANT EXECUTE ON FUNCTION core.user_get_orders_by_freelancer(integer) TO svc_user;
GRANT EXECUTE ON FUNCTION core.user_get_orders() TO svc_user;
    -- reviews
GRANT EXECUTE ON PROCEDURE core.user_create_review(integer, integer, text, integer, jsonb) TO svc_user;
GRANT EXECUTE ON PROCEDURE core.user_update_review(integer, text, integer, jsonb) TO svc_user;
GRANT EXECUTE ON PROCEDURE core.user_delete_review(integer) TO svc_user;
GRANT EXECUTE ON FUNCTION core.user_get_reviews(integer) TO svc_user;
GRANT EXECUTE ON FUNCTION core.user_get_review_by_id(integer) TO svc_user;
    -- complaints
GRANT EXECUTE ON PROCEDURE core.user_create_complaint(integer, integer, text, jsonb) TO svc_user;
GRANT EXECUTE ON PROCEDURE core.user_update_complaint(integer, varchar, integer, integer, text) TO svc_user;
GRANT EXECUTE ON PROCEDURE core.user_delete_complaint(integer) TO svc_user;
GRANT EXECUTE ON FUNCTION core.user_get_complaints(integer) TO svc_user;
    -- portfolios
GRANT EXECUTE ON PROCEDURE core.user_create_portfolio(integer, text, jsonb, text[], text) TO svc_user;
GRANT EXECUTE ON FUNCTION core.user_get_portfolios(integer) TO svc_user;
GRANT EXECUTE ON PROCEDURE core.user_update_portfolio(integer, text, jsonb, text[], text) TO svc_user;
GRANT EXECUTE ON PROCEDURE core.user_delete_portfolio(integer) TO svc_user;


GRANT EXECUTE ON PROCEDURE core.user_send_project_invite (INT, INT, INT) TO svc_user;
GRANT EXECUTE ON PROCEDURE core.user_accept_invite (INT, INT) TO svc_user;
GRANT EXECUTE ON PROCEDURE core.user_decline_invite(INT, INT) TO svc_user;