/* user's view */
-- 1. role's view
CREATE OR REPLACE VIEW core.v_roles AS
SELECT id_role, role_name FROM core.roles;

-- 2. user's view
CREATE OR REPLACE VIEW core.v_users AS
SELECT
  u.id_user, r.role_name, u.last_name, u.first_name,
  u.middle_name, u.gender, u.registration_date,
  u.last_online_time, u.rating
FROM core.users u
JOIN core.roles r ON u.role = r.id_role;

-- 3. project's view
CREATE OR REPLACE VIEW core.v_projects AS
SELECT
  id_project, id_customer, title,
  status, description, media
FROM core.projects; 

-- 4. review's view
CREATE OR REPLACE VIEW core.v_reviews AS
SELECT
    id_review, id_order, id_author, id_recipient,
    comment, rating, media
FROM core.reviews;

-- 5. order's view
CREATE OR REPLACE VIEW core.v_orders AS
SELECT
  id_order, id_project, id_freelancer,
  status, creation_date, deadline
FROM core.orders;

-- 6. order_extended view
CREATE OR REPLACE VIEW core.v_order_extended AS
SELECT
  o.id_order      AS "OrderId",
  o.status        AS "OrderStatus",
  o.creation_date AS "OrderCreationDate",
  o.deadline      AS "OrderDeadline",

  p.id_project    AS "ProjectId",
  p.title         AS "ProjectTitle",
  p.status        AS "ProjectStatus",

  c.id_user       AS "CustomerId",
  c.first_name || ' ' || c.last_name AS "CustomerFullName",

  f.id_user       AS "FreelancerId",
  COALESCE(f.first_name || ' ' || f.last_name, 'Не назначен')
                  AS "FreelancerFullName"
FROM core.v_orders o
JOIN core.v_projects p ON o.id_project = p.id_project
JOIN core.v_users c	ON p.id_customer = c.id_user
LEFT JOIN core.v_users f ON o.id_freelancer = f.id_user;

-- 7. order_archive's view
CREATE OR REPLACE VIEW core.v_orders_archive AS
SELECT 
	id_order_arc, id_order,
	id_project, project_title,
	id_customer, id_freelancer,
	status, creation_date, deadline
FROM core.orders_archive;

-- 8. order_archive_extended view
CREATE OR REPLACE VIEW core.v_order_archive_extended AS
SELECT
  a.id_order          AS "OrderId",
  a.status            AS "OrderStatus",
  a.creation_date     AS "OrderCreationDate",
  a.deadline          AS "OrderDeadline",

  a.id_project        AS "ProjectId",
  a.project_title     AS "ProjectTitle",
  'archived'          AS "ProjectStatus",

  a.id_customer       AS "CustomerId",
  COALESCE(c.first_name || ' ' || c.last_name, 'Неизвестно') AS "CustomerFullName",

  a.id_freelancer     AS "FreelancerId",
  COALESCE(f.first_name || ' ' || f.last_name, 'Не назначен')
                      AS "FreelancerFullName"
FROM core.orders_archive a
LEFT JOIN core.v_users f ON f.id_user = a.id_freelancer
LEFT JOIN core.v_users c ON c.id_user = a.id_customer;

-- 9. portfolio's view
CREATE OR REPLACE VIEW core.v_portfolio AS
SELECT
  id_portfolio, id_user, description,
  media, skills, experience
FROM core.portfolio;

-- 10. orders_reviews view  —  «архив-заказ + оба отзыва»
CREATE OR REPLACE VIEW core.v_orders_reviews AS
SELECT
    oa.id_order_arc           AS order_id,
    oa.creation_date,

    oa.project_title,

    oa.id_customer,
    cu.first_name || ' ' || cu.last_name   AS customer_fullname,

    oa.id_freelancer,
    fu.first_name || ' ' || fu.last_name   AS freelancer_fullname,

    cr.id_review        AS customer_review_id,
    cr.comment          AS customer_comment,
    cr.rating           AS customer_rating,

    fr.id_review        AS freelancer_review_id,
    fr.comment          AS freelancer_comment,
    fr.rating           AS freelancer_rating
FROM   core.orders_archive            oa
JOIN   core.v_users              cu  ON cu.id_user = oa.id_customer
LEFT   JOIN core.v_users         fu  ON fu.id_user = oa.id_freelancer

LEFT   JOIN core.v_reviews       cr  ON cr.id_order    = oa.id_order_arc
                                   AND cr.id_author  = oa.id_customer
LEFT   JOIN core.v_reviews       fr  ON fr.id_order    = oa.id_order_arc
                                   AND fr.id_author  = oa.id_freelancer;

-- 11. all user's counterparts workers
CREATE OR REPLACE VIEW core.v_all_counterparts AS
SELECT DISTINCT CASE WHEN o.id_customer = u.id_user THEN o.id_freelancer ELSE o.id_customer END AS counterpart_id
FROM core.orders_archive o
JOIN core.v_users u ON u.id_user IN (o.id_customer, o.id_freelancer);

-- 12. v_complaints
CREATE OR REPLACE VIEW core.v_complaints AS
SELECT
  id_complaint, id_user, filed_by,
  id_moderator, status, description, media
FROM core.complaints;

-- 13. v_user_notifications
CREATE OR REPLACE VIEW core.v_user_notifications AS
SELECT  n.id_notification, n.id_project,
        p.title  AS project_title,
        n.id_sender,
        s.first_name||' '||s.last_name AS sender_name,
		n.id_receiver,
		r.first_name||' '||r.last_name AS receiver_name,
        n.created_at
FROM core.notifications n
JOIN core.projects p ON p.id_project = n.id_project
JOIN core.v_users s ON s.id_user = n.id_sender
JOIN core.v_users r on r.id_user = n.id_receiver;

-- 14. v_user_warnings
CREATE OR REPLACE VIEW core.v_user_warnings AS
SELECT
  w.id_warning,
  w.id_user      AS user_id,
  u.first_name||' '||u.last_name AS user_name,
  w.id_moderator AS moderator_id,
  m.first_name||' '||m.last_name AS moderator_name,
  w.message,
  w.issued_at,
  w.expires_at,
  w.is_resolved
FROM core.warnings w
JOIN core.users u ON w.id_user = u.id_user
JOIN core.users m ON w.id_moderator = m.id_user;


/* svc_mod */
-- 1. user's view
CREATE OR REPLACE VIEW core.v_mod_users AS
SELECT
  u.id_user, u.role AS id_role, r.role_name,u.last_name,u.first_name, 
  u.middle_name, u.gender, u.phone_number, u.email, u.registration_date,
  u.last_online_time, u.rating
FROM core.users u
JOIN core.roles r ON u.role = r.id_role;

-- 2. complaint's view
CREATE OR REPLACE VIEW core.v_mod_complaints AS
SELECT
  c.id_complaint,
    c.id_user        AS "UserComId",
    u1.first_name || ' ' || u1.last_name AS "UserComName",
    c.filed_by       AS "FiledById",
    u2.first_name || ' ' || u2.last_name AS "FiledByName",
	c.id_moderator   AS "ModeratorId",
    c.status         AS "Status",
    c.description    AS "Description",
    c.media          AS "Media"
FROM core.complaints AS c
JOIN core.users    AS u1 ON c.id_user   = u1.id_user
JOIN core.users    AS u2 ON c.filed_by = u2.id_user
WHERE c.id_user <> c.filed_by;

/*
DROP VIEW IF EXISTS core.v_roles;
DROP VIEW IF EXISTS core.v_users;
DROP VIEW IF EXISTS core.v_projects;

DROP VIEW IF EXISTS core.v_reviews;
DROP VIEW IF EXISTS core.v_orders_reviews;

DROP VIEW IF EXISTS core.v_complaints;
DROP VIEW IF EXISTS core.v_all_counterparts;

DROP VIEW IF EXISTS core.v_orders;
DROP VIEW IF EXISTS core.v_order_extended;

DROP VIEW IF EXISTS core.v_orders_archive;
DROP VIEW IF EXISTS core.v_order_archive_extended;

DROP VIEW IF EXISTS core.v_portfolio;

DROP VIEW IF EXISTS core.v_user_notifications;

DROP VIEW IF EXISTS core.v_mod_users;
DROP VIEW IF EXISTS core.v_mod_complaints;
*/