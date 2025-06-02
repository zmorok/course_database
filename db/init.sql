-- Скрипт заполнения базы данными (20 пользователей, проекты, заказы, портфолио, отзывы, жалобы, аудит)

-- 1. Роли
INSERT INTO core.roles(role_name, role_privileges) VALUES
  ('admin',     '{"admin": true}'::JSONB),
  ('moderator', '{"moderate_complaints": true}'::JSONB),
  ('user',      '{"create_project": true, "create_proposal": true}'::JSONB);

-- 2. Пользователи: admin(1), moderator(2), users 3..20
-- статические для admin и moderator
INSERT INTO core.users(
  password, role, last_name, first_name, middle_name,
  gender, phone_number, email, level, performance_score, rating
) VALUES
  (
    repeat(md5('admin_pass'),4)::CHAR(128), 1, 'Admin', 'System', NULL,
    'Other', '+70000000001', 'admin@local.com',        5, 0.00, 5.0
  ),
  (
    repeat(md5('mod_pass'),4)::CHAR(128),   2, 'Moderator', 'Anna', 'M.',
    'Female', '+70000000002', 'mod@local.com',        3, 0.00, 4.8
  );
-- динамические 18 пользователей
INSERT INTO core.users(
  password, role, last_name, first_name, middle_name,
  gender, phone_number, email, level, performance_score, rating
)
SELECT
  repeat(md5('user'||i),4)::CHAR(128) AS password,
  3 AS role,
  'Last'||i,
  'First'||i,
  NULL,
  CASE WHEN i % 2 = 0 THEN 'Female' ELSE 'Male' END AS gender,
  '+7000000'||lpad(i::text,3,'0') AS phone_number,
  'user'||i||'@example.com' AS email,
  floor(random()*5+1)::int AS level,
  round((random()*100)::numeric,2) AS performance_score,
  round((random()*5)::numeric,1) AS rating
FROM generate_series(3,20) AS s(i);

-- 3. Проекты: 2 на пользователя 3..20
INSERT INTO core.projects(
  id_customer, title, status, description, media, competition_mode
)
SELECT id_user, 'Project_'||id_user||'_1', 'open', 'Desc1 for '||id_user, '[]'::JSONB, FALSE
FROM core.users WHERE role=3
UNION ALL
SELECT id_user, 'Project_'||id_user||'_2', 'open', 'Desc2 for '||id_user, '[]'::JSONB, TRUE
FROM core.users WHERE role=3;

-- 4. Заказы: 3 на каждого freelancer
INSERT INTO core.orders(
  id_project, id_freelancer, id_payment, status, creation_date, deadline
)
SELECT
  ((u.id_user-3)*2 + ((n+1)/2)::int) AS id_project,
  u.id_user,
  NULL,
  (ARRAY['pending','active','completed'])[floor(random()*3+1)],
  NOW(),
  (CURRENT_DATE + ((random()*30+1)::int))
FROM core.users u
CROSS JOIN LATERAL generate_series(1,3) AS gs(n)
WHERE u.role = 3;

-- 5. Portfolio: по 2 записи на пользователя
INSERT INTO core.portfolio(
  id_user, description, media, skills, experience
)
SELECT
  id_user,
  'Portfolio for user '||id_user,
  '[]'::JSONB,
  ARRAY['SkillA_'||id_user, 'SkillB_'||id_user],
  (floor(random()*10)+1)||' years'
FROM core.users WHERE role = 3;

-- 6. Reviews: 2–3 на каждого recipient
INSERT INTO core.reviews(
  id_author, id_recipient, comment, rating, media
)
SELECT
  ((r.recipient_id + n) % 20) + 1 AS id_author,
  r.recipient_id,
  'Review '||n||' for user '||r.recipient_id AS comment,
  floor(random()*5+1)::int AS rating,
  '[]'::JSONB AS media
FROM (
  SELECT id_user AS recipient_id FROM core.users WHERE role = 3
) AS r
CROSS JOIN LATERAL generate_series(1, (floor(random()*2)+2)::int) AS gs(n);

-- 7. Complaints: 2–3 на каждого user
INSERT INTO core.complaints(
  id_user, status, description, media
)
SELECT
  u.id_user,
  (ARRAY['new','in_progress','resolved'])[floor(random()*3+1)],
  'Complaint '||gs.n||' by user '||u.id_user AS description,
  '[]'::JSONB AS media
FROM core.users u
CROSS JOIN LATERAL generate_series(1, (floor(random()*2)+2)::int) AS gs(n)
WHERE u.role = 3;

-- 8. Audit logs: 100 random entries
INSERT INTO core.audit_logs(
  user_id, action, table_name, record_id, old_data, new_data, changed_at
)
SELECT
  floor(random()*20+1)::int AS user_id,
  (ARRAY['INSERT','UPDATE','DELETE'])[floor(random()*3+1)] AS action,
  (ARRAY['users','projects','orders','reviews','complaints','portfolio'])[floor(random()*6+1)] AS table_name,
  floor(random()*100)+1 AS record_id,
  NULL AS old_data,
  '{}'::JSONB AS new_data,
  NOW() - ((random()*365)::int || ' days')::interval AS changed_at
FROM generate_series(1,100);
