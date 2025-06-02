INSERT INTO core.projects (id_customer,title,status,description,media)
SELECT
  (ARRAY[40,46,47,48,50])[ ((gs - 1) % 5) + 1 ],
  'Project title #' || gs,
  (ARRAY['draft','open','in_progress','completed','cancelled'])
    [ ((gs - 1) % 5) + 1 ],
  'This is a description for project #' || gs,
  CASE WHEN ((gs - 1) % 2) = 0
       THEN jsonb_build_object(
              'media_url',
              'https://example.com/media/' || gs
            )
  ELSE jsonb_build_object(
		'non_media_url',
		'https://bad.link/media/' || gs
  )
  END
FROM generate_series(1,1000000) AS gs;


truncate table core.projects restart identity cascade;

select * from core.projects;

--------------------------------------------------------------------------------
-- 1) Оценка разового плана (без выполнения)
EXPLAIN ANALYZE
SELECT *
  FROM core.projects
 WHERE id_customer = 40;
--------------------------------------------------------------------------------
-- 2) Полный расчёт плана + фактическая статистика выполнения
EXPLAIN ANALYZE
SELECT id_project, id_customer, title, description, media
  FROM core.v_projects p WHERE p.status = 'draft'

--------------------------------------------------------------------------------
select * from core.projects

-- ('draft','open','in_progress','completed','cancelled')


CREATE INDEX CONCURRENTLY idx_proj_draft_cover
  ON core.projects(status)
  INCLUDE (id_project, id_customer, title, description, media)
 WHERE status = 'draft';
 
CREATE INDEX CONCURRENTLY idx_proj_open_cover
  ON core.projects(status)
  INCLUDE (id_project, id_customer, title, description, media)
 WHERE status = 'open';

CREATE INDEX CONCURRENTLY idx_proj_in_progress_cover
  ON core.projects(status)
  INCLUDE (id_project, id_customer, title, description, media)
 WHERE status = 'in_progress';

CREATE INDEX CONCURRENTLY idx_proj_completed_cover
  ON core.projects(status)
  INCLUDE (id_project, id_customer, title, description, media)
 WHERE status = 'completed';

CREATE INDEX CONCURRENTLY idx_proj_cancelled_cover
  ON core.projects(status)
  INCLUDE (id_project, id_customer, title, description, media)
 WHERE status = 'cancelled';


VACUUM ANALYZE core.projects;


--------------------------------------------------------------------------------
-- 5) Размер таблицы и всех её индексов
SELECT
  pg_size_pretty(pg_relation_size('core.projects'))      AS table_size,
  pg_size_pretty(pg_total_relation_size('core.projects')) AS total_size_including_indexes;
--------------------------------------------------------------------------------
-- 6) Статистика использования сканов / индексов
SELECT
  relname,
  seq_scan, idx_scan,
  seq_tup_read, idx_tup_fetch
FROM pg_stat_user_tables
WHERE relname = 'projects';
--------------------------------------------------------------------------------
-- 7) Статистика по индексам (сколько раз использовались)
SELECT
  indexrelname,
  idx_scan,
  idx_tup_read,
  idx_tup_fetch
FROM pg_stat_user_indexes
WHERE relname = 'projects';
--------------------------------------------------------------------------------
-- 8) Сбросить накопленную статистику (для «чистой» оценки)
SELECT pg_stat_reset();
--------------------------------------------------------------------------------