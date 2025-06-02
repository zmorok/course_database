CREATE TABLE core.roles (
    id_role SERIAL PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    role_privileges JSONB NOT NULL
);

CREATE TABLE core.users (
    id_user SERIAL PRIMARY KEY,
    password CHAR(128) NOT NULL CHECK (length(password) = 128),
    role INTEGER NOT NULL REFERENCES core.roles(id_role) ON UPDATE CASCADE ON DELETE RESTRICT,
    last_name VARCHAR(100) NOT NULL CHECK (char_length(last_name) > 0),
    first_name VARCHAR(100) NOT NULL CHECK (char_length(first_name) > 0),
    middle_name VARCHAR(100),
    gender VARCHAR(10) CHECK (gender IN ('Male','Female','Other')),
    phone_number VARCHAR(20) CHECK (phone_number ~ '^\+?[0-9]{7,20}$'),
    email VARCHAR(100) NOT NULL UNIQUE CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    registration_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_online_time TIMESTAMP CHECK (last_online_time IS NULL OR last_online_time >= registration_date),
    rating DECIMAL(2,1) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
    photo BYTEA DEFAULT NULL
);

CREATE TABLE core.projects (
    id_project SERIAL PRIMARY KEY,
    id_customer INTEGER NOT NULL REFERENCES core.users(id_user) ON UPDATE CASCADE ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL CHECK (char_length(title) > 0),
    status VARCHAR(50) NOT NULL CHECK (status IN ('draft','open','in_progress','completed','cancelled')),
    description TEXT NOT NULL CHECK (char_length(description) > 0),
    media JSONB
);

CREATE TABLE core.reviews (
    id_review SERIAL PRIMARY KEY,
    id_order INT NOT NULL REFERENCES core.orders_archive(id_order_arc) ON UPDATE CASCADE ON DELETE CASCADE,
    id_author INT NOT NULL REFERENCES core.users(id_user) ON UPDATE CASCADE ON DELETE CASCADE,
    id_recipient INT REFERENCES core.users(id_user) ON UPDATE CASCADE ON DELETE SET NULL,
    comment TEXT NOT NULL CHECK (char_length(comment) > 0),
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    media JSONB,
    CONSTRAINT uq_review_per_side UNIQUE (id_order, id_author),
	CONSTRAINT ck_no_self_review CHECK (id_recipient IS NULL OR id_author <> id_recipient)
);

CREATE TABLE core.orders (
    id_order SERIAL PRIMARY KEY,
    id_project INTEGER NOT NULL UNIQUE REFERENCES core.projects(id_project) ON UPDATE CASCADE ON DELETE CASCADE,
    id_freelancer INTEGER NOT NULL REFERENCES core.users(id_user) ON UPDATE CASCADE ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL CHECK (status IN ('pending','active','completed','cancelled','disputed')),
    creation_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deadline DATE CHECK (deadline IS NULL OR deadline >= creation_date)
);

CREATE TABLE core.orders_archive (
	id_order_arc SERIAL PRIMARY KEY,
    id_order INT NOT NULL,
    id_project INT NOT NULL,
	project_title TEXT NOT NULL,
    id_customer INT NOT NULL REFERENCES core.users(id_user) ON UPDATE CASCADE ON DELETE CASCADE,
    id_freelancer INT REFERENCES core.users(id_user) ON UPDATE CASCADE ON DELETE CASCADE,
    status VARCHAR(50) CHECK (status IN ('completed','cancelled')),
    creation_date TIMESTAMP,
    deadline DATE
);

CREATE TABLE core.complaints (
    id_complaint SERIAL PRIMARY KEY,
    id_user INTEGER NOT NULL REFERENCES core.users(id_user) ON UPDATE CASCADE ON DELETE CASCADE,
    filed_by INTEGER NOT NULL REFERENCES core.users(id_user) ON UPDATE CASCADE ON DELETE CASCADE,
    id_moderator INTEGER REFERENCES core.users(id_user) ON UPDATE CASCADE ON DELETE SET NULL,
    status VARCHAR(50) NOT NULL CHECK (status IN ('new','in_progress','resolved','dismissed')),
    description TEXT NOT NULL CHECK (char_length(description) > 0),
    media JSONB
);


CREATE TABLE core.warnings (
  id_warning SERIAL PRIMARY KEY,
  id_user INT NOT NULL REFERENCES core.users(id_user) ON UPDATE CASCADE ON DELETE CASCADE,
  id_moderator INT NOT NULL REFERENCES core.users(id_user) ON UPDATE CASCADE ON DELETE RESTRICT,
  id_complaint INT UNIQUE NOT NULL REFERENCES core.complaints(id_complaint) ON UPDATE CASCADE ON DELETE SET NULL,
  message TEXT NOT NULL,
  issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP,
  is_resolved BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE core.portfolio (
    id_portfolio SERIAL PRIMARY KEY,
    id_user INTEGER NOT NULL REFERENCES core.users(id_user) ON UPDATE CASCADE ON DELETE CASCADE,
    description TEXT NOT NULL CHECK (char_length(description) > 0),
    media JSONB,
    skills TEXT[] NOT NULL CHECK (array_length(skills,1) >= 1),
    experience TEXT
);

CREATE TABLE core.audit_logs (
    id_log SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES core.users(id_user) ON UPDATE CASCADE ON DELETE SET NULL,
	proc_name VARCHAR(100),
    action VARCHAR(10) NOT NULL CHECK (action IN ('INSERT','UPDATE','DELETE')),
    table_name VARCHAR(50) NOT NULL,
    record_id INTEGER NOT NULL,
    old_data JSONB,
    new_data JSONB,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE core.notifications (
    id_notification SERIAL PRIMARY KEY,
    id_sender INT NOT NULL REFERENCES core.users(id_user) ON DELETE CASCADE,
    id_receiver INT NOT NULL REFERENCES core.users(id_user) ON DELETE CASCADE,
    id_project INT NOT NULL REFERENCES core.projects(id_project) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_invite_per_project UNIQUE (id_receiver, id_project)
);

/* TABLES DROPS
DROP TABLE core.orders_archive;
DROP TABLE core.audit_logs;
DROP TABLE core.portfolio;
DROP TABLE core.complaints CASCADE;
DROP TABLE core.orders;
DROP TABLE core.payments;
DROP TABLE core.reviews CASCADE;
DROP TABLE core.projects;
DROP TABLE core.users;
DROP TABLE core.roles;
*/
/* очистка всех таблиц
TRUNCATE TABLE core.orders_archive, core.audit_logs, core.portfolio, core.complaints,
               core.orders, core.reviews, core.projects, core.users, core.roles, core.notifications,
			   core.warnings
RESTART IDENTITY CASCADE;

TRUNCATE TABLE core.audit_logs RESTART IDENTITY CASCADE

TRUNCATE TABLE core.projects RESTART IDENTITY CASCADE
*/