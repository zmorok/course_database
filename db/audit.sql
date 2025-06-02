CREATE OR REPLACE FUNCTION core.fn_audit_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
  v_old      JSONB;
  v_new      JSONB;
  v_id       INT;
  v_user     INT;
  v_proc     TEXT;
  pk_column  TEXT;
BEGIN
  BEGIN
    v_user := current_setting('audit.user_id')::INT;
  EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
  END;

  -- сначала сделать проверку на parent_proc_name, потом на proc_name
  v_proc := COALESCE(
    current_setting('audit.proc_name', TRUE),
	current_setting('audit.parent_proc_name', TRUE)
  );

  IF current_setting('audit.skip', TRUE) = 'on' THEN
    RETURN NULL;
  END IF;

  v_old := CASE WHEN TG_OP = 'INSERT' THEN NULL ELSE to_jsonb(OLD) END;
  v_new := CASE WHEN TG_OP = 'DELETE' THEN NULL ELSE to_jsonb(NEW) END;

  IF TG_NARGS < 1 THEN
    RAISE EXCEPTION 'fn_audit_trigger requires 1 argument: pk_column';
  END IF;
  pk_column := TG_ARGV[0];

  v_id := COALESCE(
    (v_new ->> pk_column)::INT,
    (v_old ->> pk_column)::INT
  );

  INSERT INTO core.audit_logs (user_id,proc_name,action,table_name,record_id,old_data,new_data,changed_at)
  VALUES (v_user,v_proc,TG_OP,TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,v_id,v_old,v_new,now());

  RETURN NULL;
END;
$$;


CREATE OR REPLACE TRIGGER trg_audit_roles
  AFTER INSERT OR UPDATE OR DELETE ON core.roles
  FOR EACH ROW EXECUTE FUNCTION core.fn_audit_trigger('id_role');

CREATE OR REPLACE TRIGGER trg_audit_users
  AFTER INSERT OR UPDATE OR DELETE ON core.users
  FOR EACH ROW EXECUTE FUNCTION core.fn_audit_trigger('id_user');

CREATE OR REPLACE TRIGGER trg_audit_projects
  AFTER INSERT OR UPDATE OR DELETE ON core.projects
  FOR EACH ROW EXECUTE FUNCTION core.fn_audit_trigger('id_project');

CREATE OR REPLACE TRIGGER trg_audit_reviews
  AFTER INSERT OR UPDATE OR DELETE ON core.reviews
  FOR EACH ROW EXECUTE FUNCTION core.fn_audit_trigger('id_review');

CREATE OR REPLACE TRIGGER trg_audit_orders
  AFTER INSERT OR UPDATE OR DELETE ON core.orders
  FOR EACH ROW EXECUTE FUNCTION core.fn_audit_trigger('id_order');

CREATE OR REPLACE TRIGGER trg_audit_orders_archive
  AFTER INSERT OR UPDATE OR DELETE ON core.orders_archive
  FOR EACH ROW EXECUTE FUNCTION core.fn_audit_trigger('id_order_arc');

CREATE OR REPLACE TRIGGER trg_audit_complaints
  AFTER INSERT OR UPDATE OR DELETE ON core.complaints
  FOR EACH ROW EXECUTE FUNCTION core.fn_audit_trigger('id_complaint');

CREATE OR REPLACE TRIGGER trg_audit_warnings
  AFTER INSERT OR UPDATE OR DELETE ON core.warnings
  FOR EACH ROW EXECUTE FUNCTION core.fn_audit_trigger('id_warning');

CREATE OR REPLACE TRIGGER trg_audit_portfolio
  AFTER INSERT OR UPDATE OR DELETE ON core.portfolio
  FOR EACH ROW EXECUTE FUNCTION core.fn_audit_trigger('id_portfolio');

CREATE OR REPLACE TRIGGER trg_audit_notifications
  AFTER INSERT OR UPDATE OR DELETE ON core.notifications
  FOR EACH ROW EXECUTE FUNCTION core.fn_audit_trigger('id_notification');

