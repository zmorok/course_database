-- report in db
CREATE OR REPLACE FUNCTION core.get_schema_report(p_schema TEXT DEFAULT 'core')
RETURNS TABLE(table_name TEXT,row_count BIGINT,total_size TEXT)
LANGUAGE plpgsql STABLE AS $$
DECLARE rec RECORD; cnt BIGINT; sz TEXT;
BEGIN
  FOR rec IN
    SELECT t.table_name AS tbl
      FROM information_schema.tables AS t
     WHERE t.table_schema = p_schema
       AND t.table_type   = 'BASE TABLE'
     ORDER BY t.table_name
  LOOP
    EXECUTE format('SELECT count(*) FROM %I.%I', p_schema, rec.tbl)
      INTO cnt;

    EXECUTE format(
      'SELECT pg_size_pretty(pg_total_relation_size(%L))',
      p_schema || '.' || rec.tbl
    )
    INTO sz;

    table_name := rec.tbl;
    row_count   := cnt;
    total_size  := sz;
    RETURN NEXT;
  END LOOP;
END;
$$;

-- export report
CREATE OR REPLACE PROCEDURE core.export_schema_report(p_schema TEXT, p_path TEXT, p_format TEXT DEFAULT 'csv')
LANGUAGE plpgsql
SECURITY DEFINER
AS $body$
DECLARE
  actual_path TEXT;
  ts TEXT := to_char(now(), 'YYYYMMDD_HH24MISS');
BEGIN
  IF p_path IS NULL OR btrim(p_path) = '' THEN RAISE EXCEPTION 'Не указан путь для экспорта.'; END IF;

  IF right(p_path,1) IN ('/','\') THEN actual_path := p_path || p_schema || '_' || ts || '.' || lower(p_format);
  ELSE actual_path := p_path; END IF;

  CASE lower(p_format)
    WHEN 'csv' THEN
      EXECUTE format(
        'COPY (SELECT * FROM core.get_schema_report(%L)) TO %L WITH (FORMAT csv, HEADER true)',
        p_schema, actual_path
      );

    WHEN 'txt' THEN
      EXECUTE format(
        'COPY (SELECT * FROM core.get_schema_report(%L)) TO %L WITH (FORMAT text, DELIMITER E''\t'', HEADER true)',
        p_schema, actual_path
      );

    WHEN 'json' THEN
      EXECUTE format(
        'COPY (SELECT json_agg(t) FROM (SELECT * FROM core.get_schema_report(%L)) AS t) TO %L',
        p_schema, actual_path
      );

	WHEN 'html' THEN
      EXECUTE format($html$
		COPY (
  			SELECT '<!DOCTYPE html>'
  			UNION ALL SELECT '<html lang="ru">'
		  	UNION ALL SELECT '<head>'
		  	UNION ALL SELECT '<meta charset="UTF-8">'
		  	UNION ALL SELECT format('<title>Отчет по схеме %s</title>', %1$L)
		  	UNION ALL SELECT '<style>table{border-collapse:collapse;}th,td{border:1px solid #999;padding:4px;}</style>'
		  	UNION ALL SELECT '</head>'
		  	UNION ALL SELECT '<body>'
		  	UNION ALL SELECT format('<h2>Схема: %s (от %s)</h2>', %1$L, %2$L)
		  	UNION ALL SELECT '<table>'
		  	UNION ALL SELECT '<tr><th>Таблица</th><th>Строк</th><th>Размер</th></tr>'

		  	UNION ALL
		  	SELECT format(
				'<tr><td>%%s</td><td align="right">%%s</td><td align="right">%%s</td></tr>',
				table_name, row_count, total_size
		 	 ) FROM core.get_schema_report(%1$L)

		  	UNION ALL SELECT '</table>'
		  	UNION ALL SELECT '</body>'
		  	UNION ALL SELECT '</html>'
		) TO %3$L $html$, p_schema, ts, actual_path
	  );


    ELSE
      RAISE EXCEPTION 'Неподдерживаемый формат: %, допустимы CSV, TXT, JSON, HTML.', p_format;
  END CASE;

  RAISE NOTICE
    'Отчет по схеме "%" экспортирован в файл "%". Формат: %',
    p_schema, actual_path, p_format;
END;
$body$;

/*  USAGE
	CALL core.export_schema_report('core', 'D:\export_workify\sal\sal.txt',	'txt');
	CALL core.export_schema_report('core', 'D:\export_workify\sal\sal.csv',	'csv');
	CALL core.export_schema_report('core', 'D:\export_workify\sal\sal.html',	'html');
	CALL core.export_schema_report('core', 'D:\export_workify\sal\sal.json',	'json');
*/

/*
ALTER PROCEDURE core.export_schema_report(text, text, text) OWNER TO postgres;
GRANT EXECUTE ON PROCEDURE core.export_schema_report(text, text, text) TO svc_admin;
*/

-- update_last_time
CREATE OR REPLACE PROCEDURE core.update_user_last_online (
  p_performer_id INT,
  p_user_id INTEGER
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM set_config('audit.user_id', p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.update_user_last_online', false);
  
  UPDATE core.users
     SET last_online_time = CURRENT_TIMESTAMP
   WHERE id_user = p_user_id;

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Ошибка при сохранении времени последнего входа. Пожалуйста, попробуйте позже.';
END;
$$;

-- search_users
CREATE OR REPLACE FUNCTION core.search_users(
  current_user_id  INTEGER,
  query            TEXT DEFAULT ''
)
  RETURNS TABLE (
    id              INTEGER,
    "FullName"      TEXT,
    "SkillsPreview" TEXT,
    "CanInvite"     BOOLEAN
  )
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
AS $$
DECLARE
  v_query TEXT := COALESCE(query, '');
BEGIN
  IF current_user_id IS NULL THEN RAISE EXCEPTION 'Не указан текущий пользователь.'; END IF;

  RETURN QUERY
    SELECT  
      u.id_user AS id,
      u.first_name || ' ' || u.last_name  AS "FullName",
      COALESCE(skills.skills_preview, '')  AS "SkillsPreview",
      NOT EXISTS (
        SELECT 1
          FROM core.v_user_notifications n
         WHERE n.id_sender   = current_user_id
           AND n.id_receiver = u.id_user
      ) AS "CanInvite"
    FROM core.v_users u
    LEFT JOIN core.v_portfolio p ON p.id_user = u.id_user
    LEFT JOIN LATERAL (
      SELECT string_agg(DISTINCT skill, ', ') AS skills_preview
        FROM unnest(p.skills) AS skill
      ) skills ON TRUE
    WHERE u.id_user <> current_user_id
	  AND u.role_name = 'user'
      AND (
        v_query = ''
        OR lower(u.first_name || ' ' || u.last_name) LIKE '%' || lower(v_query) || '%'
        OR EXISTS (
          SELECT 1
            FROM unnest(p.skills) AS skill
           WHERE lower(skill) LIKE '%' || lower(v_query) || '%'
        )
      )
    ORDER BY u.first_name, u.last_name
  ;

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Ошибка при поиске пользователей. Пожалуйста, попробуйте чуть позже.';
END;
$$;

-- free_projects
CREATE OR REPLACE FUNCTION core.free_projects(
  current_user_id  INTEGER,
  freelancer_id    INTEGER
)
  RETURNS SETOF core.v_projects
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
AS $$
BEGIN
  IF current_user_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор текущего пользователя.'; END IF;
  IF freelancer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор фрилансера.'; END IF;

  BEGIN
    RETURN QUERY
	    SELECT p.*
	      FROM core.v_projects p
	     WHERE p.id_customer = current_user_id
	       AND NOT EXISTS (
	         SELECT 1
	           FROM core.v_user_notifications n
	          WHERE n.id_project   = p.id_project
	            AND n.id_receiver  = freelancer_id
	       );
	
  EXCEPTION
	    WHEN OTHERS THEN
	      RAISE EXCEPTION 'Ошибка при получении списка свободных проектов. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- user_counterparts
CREATE OR REPLACE FUNCTION core.user_counterparts(
  user_id INTEGER
)
  RETURNS TABLE (
    "Id"       INTEGER,
    "FullName" TEXT
  )
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
AS $$
BEGIN
  IF user_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;

  BEGIN
  RETURN QUERY
    SELECT DISTINCT
      u.id_user                                         AS "Id",
      u.first_name || ' ' || u.last_name                AS "FullName"
    FROM core.v_all_counterparts cp
    JOIN core.v_users u
      ON u.id_user = cp.counterpart_id
    WHERE cp.counterpart_id <> user_id
      AND user_id IN (
        SELECT id_customer
          FROM core.v_orders_archive
         WHERE id_freelancer = cp.counterpart_id
        UNION
        SELECT id_freelancer
          FROM core.v_orders_archive
         WHERE id_customer   = cp.counterpart_id
      );

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при получении списка контрагентов. Пожалуйста, попробуйте чуть позже.';
  END;
END;
$$;


-- ==================================================================
-- 						SVC_ADMIN
-- ==================================================================
-- 1. Create user
CREATE OR REPLACE PROCEDURE core.admin_create_user (
  p_performer_id INT,
  p_password     CHAR(128),
  p_role         INT,
  p_last_name    VARCHAR,
  p_first_name   VARCHAR,
  p_middle_name  VARCHAR DEFAULT NULL,
  p_gender       VARCHAR DEFAULT NULL,
  p_phone        VARCHAR DEFAULT NULL,
  p_email        VARCHAR DEFAULT NULL,
  p_rating       NUMERIC(2,1) DEFAULT 0.0
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор администратора.';END IF;
  IF p_password IS NULL OR length(trim(p_password)) = 0 THEN RAISE EXCEPTION 'Не указан пароль нового пользователя.'; END IF;
  IF p_role IS NULL THEN RAISE EXCEPTION 'Не задана роль нового пользователя.'; END IF;
  IF p_last_name IS NULL OR length(trim(p_last_name)) = 0 THEN RAISE EXCEPTION 'Не указана фамилия нового пользователя.'; END IF;
  IF p_first_name IS NULL OR length(trim(p_first_name)) = 0 THEN RAISE EXCEPTION 'Не указано имя нового пользователя.'; END IF;

  PERFORM set_config('audit.user_id',   p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.admin_create_user', false);

  BEGIN
    INSERT INTO core.users (password,role,last_name,first_name,middle_name,gender,phone_number,email,rating) 
    VALUES (p_password,p_role,p_last_name,p_first_name,p_middle_name,p_gender,p_phone,p_email,p_rating);
  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при создании пользователя. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 2. Update user
CREATE OR REPLACE PROCEDURE core.admin_update_user (
  p_performer_id INTEGER,
  p_id           INTEGER,
  p_password     CHAR(128)      DEFAULT NULL,
  p_role         INTEGER        DEFAULT NULL,
  p_last_name    VARCHAR        DEFAULT NULL,
  p_first_name   VARCHAR        DEFAULT NULL,
  p_middle_name  VARCHAR        DEFAULT NULL,
  p_gender       VARCHAR        DEFAULT NULL,
  p_phone        VARCHAR        DEFAULT NULL,
  p_email        VARCHAR        DEFAULT NULL,
  p_rating       NUMERIC(2,1)   DEFAULT NULL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор администратора.'; END IF;
  IF p_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя для обновления.'; END IF;

  PERFORM set_config('audit.user_id',   p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.admin_update_user', false);

  BEGIN
    UPDATE core.users
       SET
         password      = COALESCE(p_password,     password),
         role          = COALESCE(p_role,         role),
         last_name     = COALESCE(p_last_name,    last_name),
         first_name    = COALESCE(p_first_name,   first_name),
         middle_name   = COALESCE(p_middle_name,  middle_name),
         gender        = COALESCE(p_gender,       gender),
         phone_number  = COALESCE(p_phone,        phone_number),
         email         = COALESCE(p_email,        email),
         rating        = COALESCE(p_rating,       rating)
       WHERE id_user = p_id;
	 IF NOT FOUND THEN RAISE EXCEPTION 'Пользователь с идентификатором % не найден.', p_id; END IF;
  EXCEPTION
     WHEN OTHERS THEN RAISE EXCEPTION 'Ошибка при обновлении данных пользователя. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 3. Delete user
CREATE OR REPLACE PROCEDURE core.admin_delete_user (
  p_performer_id INTEGER,
  p_id           INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор администратора.'; END IF;
  IF p_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя для удаления.'; END IF;

  PERFORM set_config('audit.user_id',   p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.admin_delete_user', false);

  BEGIN
    DELETE FROM core.users WHERE id_user = p_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Пользователь с идентификатором % не найден.', p_id; END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при удалении пользователя. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 4. Change user's role
CREATE OR REPLACE PROCEDURE core.admin_change_user_role (
  p_performer_id INTEGER,
  p_user_id      INTEGER,
  p_new_role     INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор администратора.'; END IF;
  IF p_user_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_new_role IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор новой роли.'; END IF;

  PERFORM set_config('audit.user_id',   p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.admin_change_user_role', false);

  IF NOT EXISTS (SELECT 1 FROM core.users WHERE id_user = p_user_id) THEN RAISE EXCEPTION 'Пользователь с id % не найден.', p_user_id; END IF;
  IF NOT EXISTS (SELECT 1 FROM core.roles WHERE id_role = p_new_role) THEN RAISE EXCEPTION 'Роль с id % не найдена.', p_new_role; END IF;

  BEGIN
    UPDATE core.users SET role = p_new_role WHERE id_user = p_user_id;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при изменении роли пользователя. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 5. Get users
CREATE OR REPLACE FUNCTION core.admin_get_users()
  RETURNS SETOF core.users
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY SELECT * FROM core.users ORDER BY id_user;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Ошибка при получении списка пользователей. Пожалуйста, попробуйте позже.';
END;
$$;


-- 6. Get user by ID
CREATE OR REPLACE FUNCTION core.admin_get_user_by_id(
  user_id INTEGER
)
  RETURNS SETOF core.users
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
AS $$
BEGIN
  IF p_user_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  RETURN QUERY SELECT * FROM core.users WHERE id_user = user_id;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Ошибка при получении данных пользователя. Пожалуйста, попробуйте позже.';
END;
$$;


-- 7. Create role
CREATE OR REPLACE PROCEDURE core.admin_create_role (
  p_performer_id INTEGER,
  p_name         VARCHAR,
  p_privileges   JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор администратора.'; END IF;
  IF p_name IS NULL OR btrim(p_name) = '' THEN RAISE EXCEPTION 'Не указано название роли.'; END IF;
  IF p_privileges IS NULL THEN RAISE EXCEPTION 'Не указаны привилегии роли.'; END IF;

  PERFORM set_config('audit.user_id',   p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.admin_create_role', false);
  
  IF EXISTS (SELECT 1 FROM core.roles WHERE role_name = p_name) THEN RAISE EXCEPTION 'Роль % уже существует.', p_name; END IF;

  BEGIN
    INSERT INTO core.roles(role_name, role_privileges)
    VALUES (p_name, p_privileges);
  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при создании роли. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 8. Update role
CREATE OR REPLACE PROCEDURE core.admin_update_role (
  p_performer_id INTEGER,
  p_id           INTEGER,
  p_privileges   JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор администратора.'; END IF;
  IF p_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор роли.'; END IF;
  IF p_privileges IS NULL THEN RAISE EXCEPTION 'Не заданы привилегии роли.'; END IF;

  PERFORM set_config('audit.user_id',   p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.admin_update_role', false);

  IF NOT EXISTS (SELECT 1 FROM core.roles WHERE id_role = p_id) THEN RAISE EXCEPTION 'Роль с id % не найдена.', p_id; END IF;
  
  BEGIN
    UPDATE core.roles SET role_privileges = p_privileges WHERE id_role = p_id;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при обновлении привилегий роли. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 9. Delete role
CREATE OR REPLACE PROCEDURE core.admin_delete_role (
  p_performer_id INTEGER,
  p_id           INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор администратора.'; END IF;
  IF p_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор роли.'; END IF;

  PERFORM set_config('audit.user_id',   p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.admin_delete_role', false);

  BEGIN
    DELETE FROM core.roles WHERE id_role = p_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Роль с идентификатором % не найдена.', p_id; END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при удалении роли. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 10. Get roles
CREATE OR REPLACE FUNCTION core.admin_get_roles()
  RETURNS SETOF core.roles
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY SELECT * FROM core.roles;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Ошибка при получении списка ролей. Пожалуйста, попробуйте позже.';
END;
$$;


-- 11. Get audit logs
CREATE OR REPLACE FUNCTION core.admin_get_audit_logs (
  p_since TIMESTAMP DEFAULT NULL,
  p_until TIMESTAMP DEFAULT NULL
)
  RETURNS SETOF core.audit_logs
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
AS $$
BEGIN
  IF p_since IS NOT NULL AND p_until IS NOT NULL AND p_since > p_until
  THEN RAISE EXCEPTION 'Начальная дата не может быть позднее конечной.'; END IF;

  BEGIN
    RETURN QUERY
      SELECT *
        FROM core.audit_logs
       WHERE (p_since IS NULL OR changed_at >= p_since)
         AND (p_until IS NULL OR changed_at <= p_until)
       ORDER BY changed_at DESC;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION
        'Ошибка при получении логов аудита. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


/*
ALTER PROCEDURE core.admin_export_audit_logs_json(text, timestamp, timestamp) OWNER TO postgres;
ALTER PROCEDURE core.admin_import_audit_logs_json(text) OWNER TO postgres;
ALTER PROCEDURE core.admin_export_db(text) OWNER TO postgres;
ALTER PROCEDURE core.admin_import_db(text) OWNER TO postgres;
	
GRANT EXECUTE ON PROCEDURE core.admin_export_audit_logs_json(text, timestamp, timestamp) TO svc_admin;
GRANT EXECUTE ON PROCEDURE core.admin_import_audit_logs_json(text) TO svc_admin;
GRANT EXECUTE ON PROCEDURE core.admin_export_db(text) TO svc_admin;
GRANT EXECUTE ON PROCEDURE core.admin_import_db(text) TO svc_admin;
*/


-- 12. Export audit logs to JSON
CREATE OR REPLACE PROCEDURE core.admin_export_audit_logs_json (
  p_filepath TEXT,
  p_since    TIMESTAMP DEFAULT NULL,
  p_until    TIMESTAMP DEFAULT NULL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  sql TEXT;
BEGIN
  IF p_filepath IS NULL OR btrim(p_filepath) = '' THEN RAISE EXCEPTION 'Не указан путь для экспорта.'; END IF;
  IF p_since IS NOT NULL AND p_until IS NOT NULL AND p_since > p_until THEN RAISE EXCEPTION 'Начальная дата не может быть позже конечной.'; END IF;
  
  SET LOCAL audit.skip = 'on';
	
  sql := 'COPY ('
      || ' SELECT COALESCE(json_agg(row_to_json(al)), ''[]'')'
      || '   FROM core.audit_logs al'
      || '  WHERE TRUE';

  IF p_since IS NOT NULL THEN
    sql := sql
        || ' AND al.changed_at >= '
        || quote_literal(p_since);
  END IF;

  IF p_until IS NOT NULL THEN
    sql := sql
        || ' AND al.changed_at <= '
        || quote_literal(p_until);
  END IF;

  sql := sql
      || ') TO '
      || quote_literal(p_filepath);

  BEGIN
    EXECUTE sql;
  EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Не удалось экспортировать логи БД: %', SQLERRM;
  END;
END;
$$;


-- 13. Import audit logs from JSON
CREATE OR REPLACE PROCEDURE core.admin_import_audit_logs_json (p_filepath TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  raw    json;
  item   json;
BEGIN
  IF p_filepath IS NULL OR btrim(p_filepath) = '' THEN RAISE EXCEPTION 'Не указан путь к файлу для импорта.'; END IF;
  
  SET LOCAL audit.skip = 'on';
  BEGIN
  TRUNCATE core.audit_logs RESTART IDENTITY;
  raw := pg_read_file(p_filepath);
  FOR item IN SELECT * FROM json_array_elements(raw) LOOP
	INSERT INTO core.audit_logs(
		user_id, action, table_name, record_id, old_data, new_data, changed_at
	)
	VALUES (
      	(item ->> 'user_id')::int,
      	item ->> 'action',
      	item ->> 'table_name',
      	(item ->> 'record_id')::int,
      	item ->  'old_data',
      	item ->  'new_data',
      	(item ->> 'changed_at')::timestamp
	);
  	END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Не удалось импортировать логи БД: %', SQLERRM;
  END;
END;
$$;


-- 14. Export of all db
CREATE OR REPLACE PROCEDURE core.admin_export_db(p_file text)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  tbls TEXT[] := ARRAY[
    'roles','users','projects','orders','orders_archive',
    'complaints','portfolio','notifications','reviews','warnings'
  ];
  parts TEXT[];
  sql TEXT;
BEGIN
  IF p_file IS NULL OR btrim(p_file) = '' THEN RAISE EXCEPTION 'Не указан путь к файлу для экспорта.'; END IF;

  SET LOCAL audit.skip = 'on';

  parts := ARRAY(
    SELECT format(
      '%L , (SELECT COALESCE(jsonb_agg(to_jsonb(t)), ''[]''::jsonb)'
      || ' FROM core.' || tbl || ' t)',
      tbl
    )
    FROM unnest(tbls) AS tbl
  );

  sql := format(
    'COPY (SELECT jsonb_build_object(%s)::text) TO %L',
    array_to_string(parts, ', '),
    p_file
  );

  BEGIN
    EXECUTE sql;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE WARNING 'Не удалось экспортировать БД: %', SQLERRM;
  END;
END;
$$;


-- 15. Import of all db
CREATE OR REPLACE PROCEDURE core.admin_import_db(p_file TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  dump_json  JSONB;
  tbls TEXT[] := ARRAY[
    'roles','users','projects','orders','orders_archive',
    'complaints','portfolio','notifications','reviews','warnings'
  ];
  pks  TEXT[] := ARRAY[
    'id_role','id_user','id_project','id_order','id_order_arc',
    'id_complaint','id_portfolio','id_notification','id_review','id_warning'
  ];
  i    INT;
  tbl_count INT := array_length(tbls,1);
BEGIN
  IF p_file IS NULL OR btrim(p_file) = '' THEN RAISE EXCEPTION 'Не указан путь к файлу для импорта.'; END IF;
  
  SET LOCAL audit.skip = 'on';
  dump_json := pg_read_file(p_file)::jsonb;

  -- 1) Очистка всех таблиц (audit_logs удалится каскадом)
  EXECUTE format(
    'TRUNCATE %s RESTART IDENTITY CASCADE',
    array_to_string(
      ARRAY(SELECT format('core.%I', t) FROM unnest(tbls) AS t),
      ', '
    )
  );

  -- 2) Импорт данных
  FOR i IN 1 .. tbl_count LOOP
    EXECUTE format(
      'INSERT INTO core.%I SELECT * FROM jsonb_populate_recordset(NULL::core.%I, $1 -> %L)',
      tbls[i], tbls[i], tbls[i]
    ) USING dump_json;
  END LOOP;

  -- 3) Сброс последовательностей
  FOR i IN 1 .. tbl_count LOOP
    EXECUTE format(
      'SELECT setval(
         pg_get_serial_sequence(''core.%I'', ''%I''),
         GREATEST(COALESCE((SELECT MAX(%I) FROM core.%I), 0) + 1, 1)
       )',
      tbls[i], pks[i], pks[i], tbls[i]
    );
  END LOOP;

EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Не удалось импортировать БД: %', SQLERRM;
END;
$$;

-- ==================================================================
-- 						SVC_MOD
-- ==================================================================
-- 1. Get complaints
CREATE OR REPLACE FUNCTION core.mod_get_complaints(
  p_mode TEXT DEFAULT NULL
)
  RETURNS SETOF core.complaints
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
AS $$
BEGIN
  IF p_mode IS NOT NULL AND p_mode NOT IN ('all','', 'unsolved','resolved')
  THEN RAISE EXCEPTION 'Неверное значение режима: %', p_mode; END IF;

  BEGIN
  RETURN QUERY
    SELECT *
      FROM core.complaints c
     WHERE p_mode IS NULL
        OR p_mode IN ('all','')
        OR (p_mode = 'unsolved'   AND c.status IN ('new','in_progress'))
        OR (p_mode = 'resolved'   AND c.status = 'resolved')
     ORDER BY c.id_complaint;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при получении жалоб. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 2. Resolve complaint
CREATE OR REPLACE PROCEDURE core.mod_resolve_complaint (
  p_performer_id INTEGER,
  p_id_complaint INTEGER,
  p_status VARCHAR,
  p_moderator_id INTEGER
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор модератора.'; END IF;
  IF p_id_complaint IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор жалобы.'; END IF;
  IF p_status IS NULL OR btrim(p_status) = '' THEN RAISE EXCEPTION 'Не указан новый статус жалобы.'; END IF;
  IF p_moderator_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор ответственного модератора.'; END IF;

  PERFORM set_config('audit.user_id', p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.mod_resolve_complaint', false);

  IF NOT EXISTS (
    SELECT 1
	  FROM core.complaints
     WHERE id_complaint = p_id_complaint
    ) THEN
    RAISE EXCEPTION 'Жалоба с идентификатором % не найдена.', p_id_complaint;
  END IF;

  -- core.mod_issue_warning нужео вызвать для выдаяи выдачи
  -- core.mod_delete_project или core.user_delete_project / order
  UPDATE core.complaints
     SET status       = 'resolved',
         id_moderator = p_moderator_id
   WHERE id_complaint = p_id_complaint;
END;
$$;


-- 3. Change status complaint
CREATE OR REPLACE PROCEDURE core.mod_update_complaint_status(
  p_performer_id   INTEGER,
  p_id_complaint   INTEGER,
  p_new_status     VARCHAR,
  p_moderator_id   INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор модератора.'; END IF;
  IF p_id_complaint IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор жалобы.'; END IF;
  IF p_new_status IS NULL OR btrim(p_new_status) = '' THEN RAISE EXCEPTION 'Не указан новый статус жалобы.'; END IF;
  IF p_new_status NOT IN ('new', 'in_progress', 'dismissed') THEN RAISE EXCEPTION 'Неверный статус: %', p_new_status; END IF;
  IF p_moderator_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор ответственного модератора.'; END IF;

  PERFORM set_config('audit.user_id',    p_performer_id::text, false);
  PERFORM set_config('audit.proc_name',  'core.mod_update_complaint_status', false);

  IF NOT EXISTS (SELECT 1 FROM core.complaints WHERE id_complaint = p_id_complaint)
  THEN RAISE EXCEPTION 'Жалоба с идентификатором % не найдена.', p_id_complaint; END IF;

  UPDATE core.complaints
     SET status       = p_new_status,
         id_moderator = p_moderator_id
   WHERE id_complaint = p_id_complaint;
END;
$$;


-- 4. Warn target user
CREATE OR REPLACE PROCEDURE core.mod_issue_warning(
  p_performer_id    INT,
  p_complaint_id    INT,
  p_target_user     INT,
  p_message         TEXT,
  p_expires_days    INT     DEFAULT 7
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_expires TIMESTAMP;
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор модератора.'; END IF;
  IF p_complaint_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор жалобы.'; END IF;
  IF p_target_user IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя для предупреждения.'; END IF;
  IF p_message IS NULL OR btrim(p_message) = '' THEN RAISE EXCEPTION 'Не указано сообщение предупреждения.'; END IF;
  IF p_expires_days IS NULL OR p_expires_days < 0 THEN RAISE EXCEPTION 'Неверное значение срока действия предупреждения: %', p_expires_days; END IF;

  IF NOT EXISTS (SELECT 1 FROM core.complaints WHERE id_complaint = p_complaint_id) THEN RAISE EXCEPTION 'Жалоба с идентификатором % не найдена.', p_complaint_id; END IF;
  IF NOT EXISTS (SELECT 1 FROM core.users WHERE id_user = p_target_user) THEN RAISE EXCEPTION 'Пользователь с идентификатором % не найден.', p_target_user; END IF;
  
  PERFORM set_config('audit.user_id',    p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.mod_issue_warning', false);

  v_expires := current_timestamp + (p_expires_days || ' days')::interval;

  IF EXISTS (SELECT 1 FROM core.warnings WHERE id_complaint = p_complaint_id) THEN RAISE EXCEPTION 'На эту жалобу уже выдано предупреждение.'; END IF;
  
  INSERT INTO core.warnings(id_user, id_moderator, id_complaint, message, expires_at, is_resolved)
  VALUES (p_target_user, p_performer_id, p_complaint_id, p_message, v_expires, true);
END;
$$;


-- 5. Check user
CREATE OR REPLACE FUNCTION core.mod_check_user(
  p_performer_id  INT,
  p_target_user   INT
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_result JSONB;
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор модератора.'; END IF;
  IF p_target_user IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF NOT EXISTS (SELECT 1 FROM core.users WHERE id_user = p_target_user) THEN RAISE EXCEPTION 'Пользователь с идентификатором % не найден.', p_target_user; END IF;
  
  PERFORM set_config('audit.user_id',    p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.mod_check_user', false);
  SELECT jsonb_build_object(
    'user',        jsonb_build_object(
                      'id',         u.id_user,
                      'first_name', u.first_name,
                      'last_name',  u.last_name,
                      'email',      u.email,
                      'level',      u.level,
                      'rating',     u.rating
                   ),
    'portfolio',   COALESCE(
                     (
                       SELECT jsonb_agg(
                         jsonb_build_object(
                           'id',         p.id_portfolio,
                           'description',p.description,
                           'media',      p.media,
                           'skills',     p.skills,
                           'experience', p.experience
                         )
                       )
                       FROM core.portfolio p
                       WHERE p.id_user = p_target_user
                     ),
                     '[]'::jsonb
                   ),
    'reviews',     COALESCE(
                     (
                       SELECT jsonb_agg(
                         jsonb_build_object(
                           'id',           r.id_review,
                           'comment',      r.comment,
                           'rating',       r.rating,
                           'author_id',    r.id_author,
                           'author_name',  au.first_name || ' ' || au.last_name,
                           'project_id',   oa.id_project,
                           'project_title',oa.project_title
                         )
                       )
                       FROM core.reviews r
                       JOIN core.orders_archive oa
                         ON r.id_order = oa.id_order_arc
                       JOIN core.users au
                         ON r.id_author = au.id_user
                       WHERE r.id_recipient = p_target_user
                     ),
                     '[]'::jsonb
                   )
  )
  INTO v_result;

  RETURN v_result;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Ошибка при проверке пользователя. Пожалуйста, попробуйте позже.';
END;
$$;



-- ==================================================================
-- 						SVC_USER
-- ==================================================================
-- 1. Get available users
CREATE OR REPLACE FUNCTION core.user_get_users()
  RETURNS TABLE (
    id_user            INTEGER,
    last_name          VARCHAR(100),
    first_name         VARCHAR(100),
    middle_name        VARCHAR(100),
    gender             VARCHAR(10),
    email              VARCHAR(100),
    registration_date  TIMESTAMP,
    last_online_time   TIMESTAMP,
    rating             DECIMAL(2,1)
  )
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
    SELECT id_user, last_name, first_name, middle_name, gender, email, registration_date, last_online_time, rating
    FROM core.users;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Ошибка при получении списка пользователей. Пожалуйста, попробуйте позже.';
END;
$$;


-- 2. Create project
CREATE OR REPLACE PROCEDURE core.user_create_project (
  p_performer_id INTEGER,
  p_customer INTEGER,
  p_title VARCHAR,
  p_status VARCHAR DEFAULT 'draft',
  p_description TEXT DEFAULT NULL,
  p_media JSONB DEFAULT NULL
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_customer IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор заказчика.'; END IF;
  IF p_title IS NULL OR btrim(p_title) = '' THEN RAISE EXCEPTION 'Не указано название проекта.'; END IF;
  IF p_status IS NULL OR btrim(p_status) = '' THEN RAISE EXCEPTION 'Не указан статус проекта.'; END IF;
  
  PERFORM set_config('audit.user_id', p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.user_create_project', false);

  BEGIN
  INSERT INTO core.projects(id_customer,title,status,description,media)
  VALUES(p_customer,p_title,p_status,p_description,p_media);

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при создании проекта. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 3. Update project
CREATE OR REPLACE PROCEDURE core.user_update_project (
  p_performer_id INTEGER,
  p_id INTEGER,
  p_title VARCHAR DEFAULT NULL,
  p_status VARCHAR DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_media JSONB DEFAULT NULL
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор проекта.'; END IF;
  
  PERFORM set_config('audit.user_id', p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.user_update_project', false);

  BEGIN
  UPDATE core.projects 
    SET title=COALESCE(p_title,title),
	    status=COALESCE(p_status,status),
		description=COALESCE(p_description,description),
		media=COALESCE(p_media,media)
  WHERE id_project=p_id;

  IF NOT FOUND THEN RAISE EXCEPTION 'Проект с идентификатором % не найден.', p_id; END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при обновлении проекта. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 4. Delete project
CREATE OR REPLACE PROCEDURE core.user_delete_project (
  p_performer_id INTEGER,
  p_id INTEGER
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор проекта.'; END IF;
  PERFORM set_config('audit.user_id', p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.user_delete_project', false);

  BEGIN
    DELETE FROM core.projects WHERE id_project=p_id;
  
    IF NOT FOUND THEN RAISE EXCEPTION 'Проект с идентификатором % не найден.', p_id; END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при удалении проекта. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 5. Get customer's projects
CREATE OR REPLACE FUNCTION core.user_get_projects_by_customer(
  p_customer INTEGER
)
  RETURNS SETOF core.projects
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
AS $$
BEGIN
  IF p_customer IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор заказчика.'; END IF;

  BEGIN
    RETURN QUERY
      SELECT * FROM core.projects WHERE id_customer = p_customer ORDER BY id_project;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при получении списка проектов. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 6. Get all projects
CREATE OR REPLACE FUNCTION core.user_get_projects()
  RETURNS SETOF core.projects
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
    SELECT * FROM core.projects ORDER BY id_project;
	
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Ошибка при получении списка проектов. Пожалуйста, попробуйте позже.';
END;
$$;


-- 7. Get all projects by status
CREATE OR REPLACE FUNCTION core.user_get_projects_by_status(
  p_status VARCHAR(50)
)
  RETURNS TABLE (
    id_project   INTEGER,
    id_customer  INTEGER,
    title        VARCHAR,
    description  TEXT,
    media        JSONB
  )
  LANGUAGE plpgsql
  STABLE
  PARALLEL SAFE
  SECURITY DEFINER
AS $$
BEGIN
  IF p_status IS NULL OR btrim(p_status) = '' THEN RAISE EXCEPTION 'Не указан статус проектов.'; END IF;

  BEGIN
    RETURN QUERY
      SELECT p.id_project, p.id_customer, p.title, p.description, p.media
      FROM core.projects p WHERE p.status = p_status;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при получении проектов по статусу. Пожалуйста, попробуйте позже.';
  END;
END;
$$;

	
-- 8. Get project by id
CREATE OR REPLACE FUNCTION core.user_get_project_by_id(
  p_id INTEGER
)
  RETURNS core.projects
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
AS $$
DECLARE
  result core.projects%ROWTYPE;
BEGIN
  IF p_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор проекта.'; END IF;
  BEGIN
    SELECT * INTO result FROM core.projects WHERE id_project = p_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Проект с идентификатором % не найден.', p_id; END IF;
    RETURN result;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при получении проекта. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 9. Create order
CREATE OR REPLACE PROCEDURE core.user_create_order (
  p_performer_id INTEGER,
  p_project      INTEGER,
  p_freelancer   INTEGER,
  p_status       VARCHAR DEFAULT 'pending',
  p_deadline     DATE    DEFAULT NULL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_project IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор проекта.'; END IF;
  IF p_freelancer IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор фрилансера.'; END IF;
  IF p_status IS NULL OR btrim(p_status) = '' THEN RAISE EXCEPTION 'Не указан статус заказа.'; END IF;
  IF p_deadline IS NOT NULL AND p_deadline < CURRENT_DATE THEN RAISE EXCEPTION 'Срок заказа не может быть в прошлом.'; END IF;

  PERFORM set_config('audit.user_id',   p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.user_create_order', false);

  IF EXISTS (SELECT 1 FROM core.orders WHERE id_project = p_project) THEN RAISE EXCEPTION 'На этот проект уже есть заказ. Повторный отклик невозможен.'; END IF;

  BEGIN
    INSERT INTO core.orders (id_project, id_freelancer, status, deadline)
    VALUES (p_project, p_freelancer, p_status, p_deadline);

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при создании заказа. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 10. Update order
CREATE OR REPLACE PROCEDURE core.user_update_order (
  p_performer_id INTEGER,
  p_id           INTEGER,
  p_status       VARCHAR   DEFAULT NULL,
  p_deadline     DATE      DEFAULT NULL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор заказа.'; END IF;
  IF p_status IS NOT NULL AND btrim(p_status) = '' THEN RAISE EXCEPTION 'Неверный статус заказа.'; END IF;
  IF p_deadline IS NOT NULL AND p_deadline < CURRENT_DATE THEN RAISE EXCEPTION 'Срок заказа не может быть раньше текущей даты.'; END IF;

  PERFORM set_config('audit.user_id',   p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.user_update_order', false);

  BEGIN
    UPDATE core.orders
       SET status   = COALESCE(p_status, status),
           deadline = COALESCE(p_deadline, deadline)
     WHERE id_order = p_id;

    IF NOT FOUND THEN RAISE EXCEPTION 'Заказ с идентификатором % не найден.', p_id; END IF;

    IF p_status IN ('completed','cancelled') THEN CALL core.user_archive_order(p_performer_id, p_id); END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при обновлении заказа. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 11. Put order to archive
CREATE OR REPLACE PROCEDURE core.user_archive_order (p_performer_id int, p_order int)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_order core.orders%ROWTYPE;
  v_proj  core.projects%ROWTYPE;
  v_cust  core.users%ROWTYPE;
  v_frel  core.users%ROWTYPE;
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_order IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор заказа.'; END IF;
  
  PERFORM set_config('audit.user_id', p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.user_archive_order', false);
	
  SELECT * INTO v_order FROM core.orders WHERE id_order = p_order;
  IF NOT FOUND THEN RAISE EXCEPTION 'Заказ с идентификатором % не найден', p_order; END IF;

  SELECT * INTO v_proj FROM core.projects WHERE id_project = v_order.id_project;
  IF NOT FOUND THEN RAISE EXCEPTION 'Проект с идентификатором % не найден.', v_order.id_project; END IF;
  
  SELECT * INTO v_cust FROM core.users WHERE id_user = v_proj.id_customer;
  IF NOT FOUND THEN RAISE EXCEPTION 'Пользователь-заказчик с идентификатором % не найден.', v_proj.id_customer; END IF;
  
  SELECT * INTO v_frel FROM core.users WHERE id_user = v_order.id_freelancer;
  IF NOT FOUND THEN RAISE EXCEPTION 'Пользователь-фрилансер с идентификатором % не найден.', v_order.id_freelancer; END IF;

  BEGIN
    INSERT INTO core.orders_archive (
    id_order, id_project, id_customer,
    id_freelancer, status,
    creation_date, deadline,
    project_title)
    VALUES (
    v_order.id_order, v_order.id_project, v_proj.id_customer,
    v_order.id_freelancer, v_order.status,
    v_order.creation_date, v_order.deadline, v_proj.title)
    ON CONFLICT DO NOTHING;

    IF v_order.status = 'completed' THEN DELETE FROM core.projects WHERE id_project = v_order.id_project;
    ELSE DELETE FROM core.orders WHERE id_order = v_order.id_order; END IF;
	
  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при архивации заказа. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 12. Delete order
CREATE OR REPLACE PROCEDURE core.user_delete_order (
  p_performer_id INT,
  p_id INT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_status TEXT;
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор заказа.'; END IF;
  
  PERFORM set_config('audit.user_id', p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.user_delete_order', false);
  
  SELECT status INTO v_status FROM core.orders WHERE id_order=p_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Заказ с идентификатором % не найден', p_id; END IF;

  BEGIN
    IF v_status IN ('completed','cancelled') THEN
      CALL core.user_archive_order(p_performer_id, p_id);
    ELSE
	  UPDATE core.orders SET status = 'cancelled' WHERE id_order=p_id;
      CALL core.user_archive_order(p_performer_id, p_id);
    END IF; 
  
  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при удалении заказа. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 13. Get customer's orders
CREATE OR REPLACE FUNCTION core.user_get_orders_by_customer(
  p_customer INTEGER
)
  RETURNS SETOF core.orders
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
AS $$
BEGIN
  IF p_customer IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор заказчика.'; END IF;

  BEGIN
    RETURN QUERY
      SELECT o.* FROM core.orders o JOIN core.projects p ON o.id_project = p.id_project WHERE p.id_customer = p_customer ORDER BY o.id_order;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при получении списка заказов. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 14. Get freelancers's orders
CREATE OR REPLACE FUNCTION core.user_get_orders_by_freelancer(
  p_freelancer INTEGER
)
  RETURNS SETOF core.orders
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
AS $$
BEGIN
  IF p_freelancer IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор фрилансера.'; END IF;

  BEGIN
    RETURN QUERY
      SELECT * FROM core.orders WHERE id_freelancer = p_freelancer ORDER BY id_order;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при получении списка ваших заказов. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 15. Get orders
CREATE OR REPLACE FUNCTION core.user_get_orders()
  RETURNS SETOF core.orders
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
    SELECT * FROM core.orders ORDER BY id_order;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Ошибка при получении списка заказов. Пожалуйста, попробуйте позже.';
END;
$$;


-- 16. Create review
CREATE OR REPLACE PROCEDURE core.user_create_review (
	p_performer_id INT,
    p_order_arc INT,
    p_author    INT,
    p_comment   TEXT,
    p_rating    INT,
    p_media     JSONB DEFAULT NULL
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_arch core.orders_archive%ROWTYPE;
    v_rec  INT;
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_order_arc IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор заказа.'; END IF;
  IF p_author IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор автора отзыва.'; END IF;
  IF p_comment IS NULL OR btrim(p_comment) = '' THEN RAISE EXCEPTION 'Не указан текст отзыва.'; END IF;
  IF p_rating IS NULL OR p_rating < 1 OR p_rating > 5 THEN RAISE EXCEPTION 'Неверный рейтинг: % (должен быть от 1 до 5).', p_rating; END IF;
  
  PERFORM set_config('audit.user_id', p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.user_create_review', false);

  SELECT * INTO v_arch FROM core.orders_archive WHERE id_order_arc = p_order_arc;

  IF NOT FOUND THEN RAISE EXCEPTION 'Заказа с идентификатором % в архиве не был найден', p_order_arc; END IF;

  IF p_author NOT IN (v_arch.id_customer, v_arch.id_freelancer) THEN RAISE EXCEPTION 'Поользователь % не участвовал в заказе %', p_author, p_order_arc; END IF;

  v_rec :=
	CASE
	  WHEN p_author = v_arch.id_customer   THEN v_arch.id_freelancer
	  ELSE v_arch.id_customer
	END;

  INSERT INTO core.reviews (id_order, id_author, id_recipient, comment, rating, media)
  VALUES (p_order_arc, p_author, v_rec, p_comment, p_rating, p_media);
END;
$$;


-- 17. Update review
CREATE OR REPLACE PROCEDURE core.user_update_review (
	p_performer_id INT,
    p_id        INT,
    p_author    INT,
    p_comment   TEXT   DEFAULT NULL,
    p_rating    INT    DEFAULT NULL,
    p_media     JSONB  DEFAULT NULL
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор отзыва.'; END IF;
  IF p_author IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор автора.'; END IF;
  IF p_rating IS NOT NULL AND (p_rating < 1 OR p_rating > 5) THEN RAISE EXCEPTION 'Неверный рейтинг: % (должен быть от 1 до 5).', p_rating; END IF;
  
  PERFORM set_config('audit.user_id', p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.user_update_review', false);

  BEGIN
    UPDATE core.reviews
      SET comment = COALESCE(p_comment, comment),
	     rating  = COALESCE(p_rating , rating ),
	     media   = COALESCE(p_media  , media  )
      WHERE id_review = p_id
       AND id_author = p_author;

    IF NOT FOUND THEN RAISE EXCEPTION 'Отзыв % не был найден или не принадлежит пользователю %', p_id, p_author; END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при обновлении отзыва. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 18. Delete review
CREATE OR REPLACE PROCEDURE core.user_delete_review (
	p_performer_id INT,
    p_id     INT,
    p_author INT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор отзыва.'; END IF;
  IF p_author IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор автора.'; END IF;

  PERFORM set_config('audit.user_id', p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.user_delete_review', false);

  BEGIN
    DELETE FROM core.reviews WHERE id_review = p_id AND id_author = p_author;
    IF NOT FOUND THEN RAISE EXCEPTION 'Отзыв % не был найден или не принадлежит вам.', p_id; END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при удалении отзыва. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 19. Get reviews
CREATE OR REPLACE FUNCTION core.user_get_reviews(
  p_user INT
)
  RETURNS SETOF core.reviews
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
AS $$
BEGIN
  IF p_user IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя для получения отзывов.'; END IF;

  BEGIN
    RETURN QUERY
      SELECT * FROM core.reviews WHERE id_recipient = p_user ORDER BY id_review;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при получении отзывов. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 20. Get review by id
CREATE OR REPLACE FUNCTION core.user_get_review_by_id(
  p_id INT
)
  RETURNS core.reviews
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
AS $$
DECLARE
  result core.reviews%ROWTYPE;
BEGIN
  IF p_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор отзыва.'; END IF;
  
  BEGIN
    SELECT * INTO result FROM core.reviews WHERE id_review = p_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Отзыв с идентификатором % не найден.', p_id; END IF;
    RETURN result;
  
  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при получении отзыва. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 21. Create complaint
CREATE OR REPLACE PROCEDURE core.user_create_complaint(
  p_performer_id INT,
  p_filed_by     INT,
  p_id_user      INT,
  p_description  TEXT,
  p_media        JSONB DEFAULT NULL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_filed_by IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор подателя жалобы.'; END IF;
  IF p_id_user IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя, на которого подают жалобу.'; END IF;
  IF p_description IS NULL OR btrim(p_description) = '' THEN RAISE EXCEPTION 'Не указано описание жалобы.'; END IF;

  PERFORM set_config('audit.user_id',   p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.user_create_complaint', false);

  BEGIN
    INSERT INTO core.complaints(filed_by, id_user, status, description, media)
    VALUES (p_filed_by, p_id_user, 'new', p_description, p_media);

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при создании жалобы. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 22. Update complaint
CREATE OR REPLACE PROCEDURE core.user_update_complaint (
  p_performer_id INT,
  p_id           INT,
  p_status       VARCHAR     DEFAULT NULL,
  p_moderator    INT         DEFAULT NULL,
  p_who_solved   INT         DEFAULT NULL,
  p_description  TEXT        DEFAULT NULL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор жалобы.'; END IF;

  PERFORM set_config('audit.user_id',   p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.user_update_complaint', false);

  BEGIN
    UPDATE core.complaints
       SET status       = COALESCE(p_status,      status),
           id_moderator = COALESCE(p_moderator,   id_moderator),
           who_solved   = COALESCE(p_who_solved,  who_solved),
           description  = COALESCE(p_description, description)
     WHERE id_complaint = p_id;

    IF NOT FOUND THEN RAISE EXCEPTION 'Жалоба с идентификатором % не найдена.', p_id; END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при обновлении жалобы. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 23. Delete complaint
CREATE OR REPLACE PROCEDURE core.user_delete_complaint (
  p_performer_id INTEGER,
  p_id           INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор жалобы.'; END IF;

  PERFORM set_config('audit.user_id',   p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.user_delete_complaint', false);

  BEGIN
    DELETE FROM core.complaints WHERE id_complaint = p_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Жалоба с идентификатором % не найдена.', p_id; END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при удалении жалобы. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 24. Get user's complaints
CREATE OR REPLACE FUNCTION core.user_get_complaints(
  user_id INTEGER
)
  RETURNS TABLE (
    "Id_Complaint" INTEGER,
    "Id_User"      INTEGER,
    "Filed_By"     INTEGER,
    "TargetName"   TEXT,
    "Status"       VARCHAR(50),
    "Description"  TEXT
  )
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
AS $$
BEGIN
  IF user_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;

  BEGIN
    RETURN QUERY
      SELECT
        c.id_complaint AS "Id_Complaint",
        c.id_user      AS "Id_User",
        c.filed_by     AS "Filed_By",
        COALESCE(u.first_name || ' ' || u.last_name, '[удалён]') AS "TargetName",
        c.status       AS "Status",
        c.description  AS "Description"
      FROM core.v_complaints c
      LEFT JOIN core.v_users u ON u.id_user = c.id_user
      WHERE c.filed_by = user_id
      ORDER BY c.id_complaint DESC;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при получении списка жалоб. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 25. Create portfolio
CREATE OR REPLACE PROCEDURE core.user_create_portfolio (
  p_performer_id INTEGER,
  p_user INTEGER,
  p_description TEXT,
  p_media JSONB,
  p_skills TEXT[],
  p_experience TEXT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_user IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор владельца портфолио.'; END IF;
  IF p_description IS NULL OR btrim(p_description) = '' THEN RAISE EXCEPTION 'Не указано описание портфолио.'; END IF;
  IF p_skills IS NULL OR array_length(p_skills,1) = 0 THEN RAISE EXCEPTION 'Набор навыков не может быть пустым.'; END IF;
  IF p_experience IS NULL OR btrim(p_experience) = '' THEN RAISE EXCEPTION 'Не указан опыт работы.'; END IF;
  
  PERFORM set_config('audit.user_id', p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.user_create_portfolio', false);

  BEGIN
    INSERT INTO core.portfolio (id_user, description, media, skills, experience)
    VALUES (p_user, p_description, p_media, p_skills, p_experience);

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при создании портфолио. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 26. Get user's portfolios
CREATE OR REPLACE FUNCTION core.user_get_portfolios(
  p_user INTEGER
)
  RETURNS SETOF core.portfolio
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
AS $$
BEGIN
  IF p_user IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;

  BEGIN
    RETURN QUERY
      SELECT * FROM core.portfolio WHERE id_user = p_user ORDER BY id_portfolio;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при получении портфолио. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 27. Update portfolio
CREATE OR REPLACE PROCEDURE core.user_update_portfolio (
  p_performer_id INTEGER,
  p_user         INTEGER,
  p_portfolio    INTEGER,
  p_description  TEXT      DEFAULT NULL,
  p_media        JSONB     DEFAULT NULL,
  p_skills       TEXT[]    DEFAULT NULL,
  p_experience   TEXT      DEFAULT NULL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_user IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор владельца портфолио.'; END IF;
  IF p_portfolio IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор портфолио.'; END IF;

  PERFORM set_config('audit.user_id',   p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.user_update_portfolio', false);

  BEGIN
    UPDATE core.portfolio
       SET description = COALESCE(p_description, description),
           media       = COALESCE(p_media,       media),
           skills      = COALESCE(p_skills,      skills),
           experience  = COALESCE(p_experience,  experience)
     WHERE id_user      = p_user
       AND id_portfolio = p_portfolio;

    IF NOT FOUND THEN RAISE EXCEPTION 'Портфолио с идентификатором % не найдено для пользователя %.', p_portfolio, p_user; END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при обновлении портфолио. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 28. Delete portfolio
CREATE OR REPLACE PROCEDURE core.user_delete_portfolio (
  p_performer_id INTEGER,
  p_user         INTEGER,
  p_portfolio    INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_user IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор владельца портфолио.'; END IF;
  IF p_portfolio IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор портфолио.'; END IF;

  PERFORM set_config('audit.user_id',   p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.user_delete_portfolio', false);

  BEGIN
    DELETE FROM core.portfolio WHERE id_user = p_user AND id_portfolio = p_portfolio;
    IF NOT FOUND THEN RAISE EXCEPTION 'Портфолио с идентификатором % не найдено для пользователя %.', p_portfolio, p_user; END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при удалении портфолио. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 29. Update self profile
CREATE OR REPLACE PROCEDURE core.user_update_profile (
  p_performer_id INTEGER,
  p_id           INTEGER,
  p_password     CHAR(128) DEFAULT NULL,
  p_last_name    VARCHAR    DEFAULT NULL,
  p_first_name   VARCHAR    DEFAULT NULL,
  p_middle_name  VARCHAR    DEFAULT NULL,
  p_gender       VARCHAR    DEFAULT NULL,
  p_phone        VARCHAR    DEFAULT NULL,
  p_email        VARCHAR    DEFAULT NULL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор профиля.'; END IF;

  PERFORM set_config('audit.user_id',   p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.user_update_profile', false);

  BEGIN
    UPDATE core.users
       SET password     = COALESCE(p_password,     password),
           last_name    = COALESCE(p_last_name,    last_name),
           first_name   = COALESCE(p_first_name,   first_name),
           middle_name  = COALESCE(p_middle_name,  middle_name),
           gender       = COALESCE(p_gender,       gender),
           phone_number = COALESCE(p_phone,        phone_number),
           email        = COALESCE(p_email,        email)
     WHERE id_user = p_id;

    IF NOT FOUND THEN RAISE EXCEPTION 'Пользователь с идентификатором % не найден.', p_id; END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при обновлении профиля. Пожалуйста, попробуйте позже.';
  END;
END;
$$;

-- 29.1 Update self profile with photo
CREATE OR REPLACE PROCEDURE core.user_update_profile (
  p_performer_id INTEGER,
  p_id           INTEGER,
  p_password     CHAR(128) DEFAULT NULL,
  p_last_name    VARCHAR    DEFAULT NULL,
  p_first_name   VARCHAR    DEFAULT NULL,
  p_middle_name  VARCHAR    DEFAULT NULL,
  p_gender       VARCHAR    DEFAULT NULL,
  p_phone        VARCHAR    DEFAULT NULL,
  p_email        VARCHAR    DEFAULT NULL,
  p_photo        bytea		DEFAULT NULL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор профиля.'; END IF;

  PERFORM set_config('audit.user_id',   p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.user_update_profile', false);

  BEGIN
    UPDATE core.users
       SET password     = COALESCE(p_password,     password),
           last_name    = COALESCE(p_last_name,    last_name),
           first_name   = COALESCE(p_first_name,   first_name),
           middle_name  = COALESCE(p_middle_name,  middle_name),
           gender       = COALESCE(p_gender,       gender),
           phone_number = COALESCE(p_phone,        phone_number),
           email        = COALESCE(p_email,        email),
		   photo =
               CASE
                   WHEN p_photo IS NULL THEN photo      -- оставить как есть
                   WHEN octet_length(p_photo) = 0 THEN NULL  -- удалить
                   ELSE p_photo                          -- сохранить новые байты
               END
     WHERE id_user = p_id;

    IF NOT FOUND THEN RAISE EXCEPTION 'Пользователь с идентификатором % не найден.', p_id; END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при обновлении профиля. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 30. Send invite
CREATE OR REPLACE PROCEDURE core.user_send_project_invite (
  p_performer_id INTEGER,
  p_sender       INT,
  p_receiver     INT,
  p_project      INT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_sender IS NULL THEN RAISE EXCEPTION 'Не указан отправитель приглашения.'; END IF;
  IF p_receiver IS NULL THEN RAISE EXCEPTION 'Не указан получатель приглашения.'; END IF;
  IF p_project IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор проекта.'; END IF;

  PERFORM set_config('audit.user_id',   p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.user_send_project_invite', false);

  IF EXISTS (SELECT 1 FROM core.orders WHERE id_project = p_project) THEN RAISE EXCEPTION 'Проект % уже занят.', p_project; END IF;

  BEGIN
    INSERT INTO core.notifications(id_sender, id_receiver, id_project)
    VALUES (p_sender, p_receiver, p_project);
  EXCEPTION
    WHEN unique_violation THEN
      RAISE EXCEPTION 'Такое приглашение уже существует.';
  END;

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Ошибка при отправке приглашения. Пожалуйста, попробуйте позже.';
END;
$$;


/*на это не срабатывает триггер*/
-- 31. accept invite
CREATE OR REPLACE PROCEDURE core.user_accept_invite (
  p_performer_id INTEGER,
  p_notification INTEGER,
  p_freelancer   INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_row core.notifications%ROWTYPE;
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_notification IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор приглашения.';END IF;
  IF p_freelancer IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор фрилансера.'; END IF;

  PERFORM set_config('audit.user_id',         p_performer_id::text, false);
  PERFORM set_config('audit.proc_name',       'core.user_accept_invite', false);
  PERFORM set_config('audit.parent_proc_name','core.user_accept_invite', false);

  SELECT * INTO v_row FROM core.notifications WHERE id_notification = p_notification AND id_receiver = p_freelancer;
  IF NOT FOUND THEN RAISE EXCEPTION 'Приглашение с идентификатором % не найдено или не предназначено для вас.', p_notification; END IF;

  BEGIN
    CALL core.user_create_order(p_performer_id, v_row.id_project, p_freelancer, 'pending', NULL);

    DELETE FROM core.notifications WHERE id_notification = p_notification;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при принятии приглашения. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- 32. decline invite
CREATE OR REPLACE PROCEDURE core.user_decline_invite (
  p_performer_id INTEGER,
  p_notification INTEGER,
  p_freelancer   INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_performer_id IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор пользователя.'; END IF;
  IF p_notification IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор приглашения.'; END IF;
  IF p_freelancer IS NULL THEN RAISE EXCEPTION 'Не указан идентификатор фрилансера.'; END IF;

  PERFORM set_config('audit.user_id',   p_performer_id::text, false);
  PERFORM set_config('audit.proc_name', 'core.user_decline_invite', false);

  BEGIN
    DELETE FROM core.notifications WHERE id_notification = p_notification AND id_receiver = p_freelancer;
    IF NOT FOUND THEN RAISE EXCEPTION 'Приглашение с идентификатором % не найдено или не принадлежит вам.', p_notification; END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Ошибка при отклонении приглашения. Пожалуйста, попробуйте позже.';
  END;
END;
$$;


-- AUTO CLEAN OF NOTIFICATIONS
CREATE OR REPLACE FUNCTION core.f_notif_cleanup() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('audit.skip', 'on', true);
	
  BEGIN
    DELETE FROM core.notifications WHERE id_project = NEW.id_project;
  EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Ошибка очистки уведомлений для проекта %: %', NEW.id_project, SQLERRM;
  END;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_notif_cleanup
AFTER INSERT ON core.orders
FOR EACH ROW EXECUTE FUNCTION core.f_notif_cleanup();


-- ==================================================================
-- DROP existing FUNCTIONS and PROCEDURES in schema core
-- ==================================================================
/*
-- 1) Триггер очистки уведомлений и его функция
DROP TRIGGER IF EXISTS trg_notif_cleanup ON core.orders;
DROP FUNCTION IF EXISTS core.f_notif_cleanup();

-- 2) CRUD-процедуры и вспомогательные процедуры

DROP PROCEDURE IF EXISTS core.update_user_last_online(integer);

DROP PROCEDURE IF EXISTS core.admin_create_user(integer, character(128),integer, varchar,varchar,varchar,varchar,varchar,integer,numeric,numeric);
DROP PROCEDURE IF EXISTS core.admin_update_user(integer,integer,character(128),integer,varchar,varchar,varchar,varchar,varchar,integer,numeric,numeric);
DROP PROCEDURE IF EXISTS core.admin_delete_user(integer, integer);
DROP PROCEDURE IF EXISTS core.admin_change_user_role(integer, integer, integer);

DROP PROCEDURE IF EXISTS core.admin_create_role(integer, varchar, jsonb);
DROP PROCEDURE IF EXISTS core.admin_update_role(integer, integer, jsonb);
DROP PROCEDURE IF EXISTS core.admin_delete_role(integer, integer);

DROP PROCEDURE IF EXISTS core.admin_export_audit_logs_json(text, timestamp, timestamp);
DROP PROCEDURE IF EXISTS core.admin_import_audit_logs_json(text);

DROP PROCEDURE IF EXISTS core.mod_resolve_complaint(integer, integer, varchar, integer);

DROP PROCEDURE IF EXISTS core.user_create_project(integer,integer,varchar,varchar,text,jsonb,boolean);
DROP PROCEDURE IF EXISTS core.user_update_project(integer,integer,varchar,varchar,text,jsonb,boolean);
DROP PROCEDURE IF EXISTS core.user_delete_project(integer, integer);

DROP PROCEDURE IF EXISTS core.user_create_order(integer,integer,integer,varchar,date);
DROP PROCEDURE IF EXISTS core.user_update_order(integer,integer,varchar,date);
DROP PROCEDURE IF EXISTS core.user_archive_order(integer, integer);
DROP PROCEDURE IF EXISTS core.user_delete_order(integer, integer);

DROP PROCEDURE IF EXISTS core.user_create_review(integer,integer,integer,text,integer,jsonb);
DROP PROCEDURE IF EXISTS core.user_update_review(integer,integer,integer,text,integer,jsonb);
DROP PROCEDURE IF EXISTS core.user_delete_review(integer, integer, integer);

DROP PROCEDURE IF EXISTS core.user_create_complaint(integer,integer,integer,text,jsonb);
DROP PROCEDURE IF EXISTS core.user_update_complaint(integer,integer,varchar,integer,integer,text);
DROP PROCEDURE IF EXISTS core.user_delete_complaint(integer, integer);

DROP PROCEDURE IF EXISTS core.user_create_portfolio(integer,integer,text,jsonb,text[],text);
DROP PROCEDURE IF EXISTS core.user_update_portfolio(integer,integer,integer,text,jsonb,text[],text);
DROP PROCEDURE IF EXISTS core.user_delete_portfolio(integer, integer, integer);

DROP PROCEDURE IF EXISTS core.user_update_profile(integer,integer,character(128),varchar,varchar,varchar,varchar,varchar);

DROP PROCEDURE IF EXISTS core.user_send_project_invite(integer, integer, integer, integer);
DROP PROCEDURE IF EXISTS core.user_accept_invite(integer, integer, integer);
DROP PROCEDURE IF EXISTS core.user_decline_invite(integer, integer, integer);

-- 3) Функции-просмотры

DROP FUNCTION IF EXISTS core.admin_get_users();
DROP FUNCTION IF EXISTS core.admin_get_user_by_id(integer);

DROP FUNCTION IF EXISTS core.admin_get_roles();
DROP FUNCTION IF EXISTS core.admin_get_audit_logs(timestamp, timestamp);

DROP FUNCTION IF EXISTS core.mod_get_complaints(text);

DROP FUNCTION IF EXISTS core.user_get_users();

DROP FUNCTION IF EXISTS core.user_get_projects_by_customer(integer);
DROP FUNCTION IF EXISTS core.user_get_projects();
DROP FUNCTION IF EXISTS core.user_get_project_by_id(integer);

DROP FUNCTION IF EXISTS core.user_get_orders_by_customer(integer);
DROP FUNCTION IF EXISTS core.user_get_orders_by_freelancer(integer);
DROP FUNCTION IF EXISTS core.user_get_orders();

DROP FUNCTION IF EXISTS core.user_get_reviews(integer);
DROP FUNCTION IF EXISTS core.user_get_review_by_id(integer);

DROP FUNCTION IF EXISTS core.user_get_complaints(integer);

DROP FUNCTION IF EXISTS core.user_get_portfolios(integer);
*/