CREATE SCHEMA "core";

CREATE TABLE "core"."roles" (
  "id_role" SERIAL NOT NULL,
  "role_name" VARCHAR(50) NOT NULL,
  "role_privileges" JSONB NOT NULL,
  PRIMARY KEY ("id_role")
);

CREATE TABLE "core"."users" (
  "id_user" SERIAL NOT NULL,
  "password" "CHAR (128)" NOT NULL,
  "role" INTEGER NOT NULL,
  "last_name" VARCHAR(100) NOT NULL,
  "first_name" VARCHAR(100) NOT NULL,
  "middle_name" VARCHAR(100),
  "gender" VARCHAR(10),
  "phone_number" VARCHAR(20),
  "email" VARCHAR(100) NOT NULL,
  "registration_date" TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  "last_online_time" TIMESTAMP,
  "rating" DECIMAL(2,1) DEFAULT 0,
  PRIMARY KEY ("id_user")
);

CREATE TABLE "core"."projects" (
  "id_project" SERIAL NOT NULL,
  "id_customer" INTEGER NOT NULL,
  "title" VARCHAR(200) NOT NULL,
  "status" VARCHAR(50) NOT NULL,
  "description" TEXT NOT NULL,
  "media" JSONB,
  PRIMARY KEY ("id_project")
);

CREATE TABLE "core"."reviews" (
  "id_review" SERIAL NOT NULL,
  "id_order" INT NOT NULL,
  "id_author" INT NOT NULL,
  "id_recipient" INT,
  "comment" TEXT NOT NULL,
  "rating" INT NOT NULL,
  "media" JSONB,
  PRIMARY KEY ("id_review")
);

CREATE TABLE "core"."orders" (
  "id_order" SERIAL NOT NULL,
  "id_project" INTEGER NOT NULL,
  "id_freelancer" INTEGER NOT NULL,
  "status" VARCHAR(50) NOT NULL,
  "creation_date" TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  "deadline" DATE,
  PRIMARY KEY ("id_order")
);

CREATE TABLE "core"."orders_archive" (
  "id_order_arc" SERIAL NOT NULL,
  "id_order" INT NOT NULL,
  "id_project" INT NOT NULL,
  "project_title" TEXT NOT NULL,
  "id_customer" INT NOT NULL,
  "id_freelancer" INT,
  "status" VARCHAR(50),
  "creation_date" TIMESTAMP,
  "deadline" DATE,
  PRIMARY KEY ("id_order_arc")
);

CREATE TABLE "core"."complaints" (
  "id_complaint" SERIAL NOT NULL,
  "id_user" INTEGER NOT NULL,
  "filed_by" INTEGER NOT NULL,
  "id_moderator" INTEGER,
  "status" VARCHAR(50) NOT NULL,
  "description" TEXT NOT NULL,
  "media" JSONB,
  PRIMARY KEY ("id_complaint")
);

CREATE TABLE "core"."portfolio" (
  "id_portfolio" SERIAL NOT NULL,
  "id_user" INTEGER NOT NULL,
  "description" TEXT NOT NULL,
  "media" JSONB,
  "skills" TEXT[] NOT NULL,
  "experience" TEXT,
  PRIMARY KEY ("id_portfolio")
);

CREATE TABLE "core"."audit_logs" (
  "id_log" SERIAL NOT NULL,
  "user_id" INTEGER,
  "proc_name" VARCHAR(100),
  "action" VARCHAR(10) NOT NULL,
  "table_name" VARCHAR(50) NOT NULL,
  "record_id" INTEGER NOT NULL,
  "old_data" JSONB,
  "new_data" JSONB,
  "changed_at" TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  PRIMARY KEY ("id_log")
);

CREATE TABLE "core"."notifications" (
  "id_notification" SERIAL NOT NULL,
  "id_sender" INT NOT NULL,
  "id_receiver" INT NOT NULL,
  "id_project" INT NOT NULL,
  "created_at" TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  PRIMARY KEY ("id_notification")
);

CREATE TABLE "core"."warnings" (
  "id_warning" SERIAL PRIMARY KEY,
  "id_user" INT NOT NULL,
  "id_moderator" INT NOT NULL,
  "id_complaint" INT UNIQUE NOT NULL,
  "message" TEXT NOT NULL,
  "issued_at" TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  "expires_at" TIMESTAMP,
  "is_resolved" BOOLEAN NOT NULL DEFAULT false
);

CREATE UNIQUE INDEX "uq_roles_role_name" ON "core"."roles" ("role_name");

CREATE UNIQUE INDEX "uq_users_email" ON "core"."users" ("email");

CREATE UNIQUE INDEX "uq_reviews_per_side" ON "core"."reviews" ("id_order", "id_author");

CREATE UNIQUE INDEX "uq_orders_project" ON "core"."orders" ("id_project");

CREATE UNIQUE INDEX "uq_notifications_per_project" ON "core"."notifications" ("id_receiver", "id_project");

ALTER TABLE "core"."users" ADD CONSTRAINT "fk_users_role" FOREIGN KEY ("role") REFERENCES "core"."roles" ("id_role") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "core"."projects" ADD CONSTRAINT "fk_projects_customer" FOREIGN KEY ("id_customer") REFERENCES "core"."users" ("id_user") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "core"."reviews" ADD CONSTRAINT "fk_reviews_order" FOREIGN KEY ("id_order") REFERENCES "core"."orders_archive" ("id_order_arc") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "core"."reviews" ADD CONSTRAINT "fk_reviews_author" FOREIGN KEY ("id_author") REFERENCES "core"."users" ("id_user") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "core"."reviews" ADD CONSTRAINT "fk_reviews_recipient" FOREIGN KEY ("id_recipient") REFERENCES "core"."users" ("id_user") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "core"."orders" ADD CONSTRAINT "fk_orders_project" FOREIGN KEY ("id_project") REFERENCES "core"."projects" ("id_project") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "core"."orders" ADD CONSTRAINT "fk_orders_freelancer" FOREIGN KEY ("id_freelancer") REFERENCES "core"."users" ("id_user") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "core"."orders_archive" ADD CONSTRAINT "fk_orders_archive_customer" FOREIGN KEY ("id_customer") REFERENCES "core"."users" ("id_user") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "core"."orders_archive" ADD CONSTRAINT "fk_orders_archive_freelancer" FOREIGN KEY ("id_freelancer") REFERENCES "core"."users" ("id_user") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "core"."complaints" ADD CONSTRAINT "fk_complaints_user" FOREIGN KEY ("id_user") REFERENCES "core"."users" ("id_user") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "core"."complaints" ADD CONSTRAINT "fk_complaints_filed_by" FOREIGN KEY ("filed_by") REFERENCES "core"."users" ("id_user") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "core"."complaints" ADD CONSTRAINT "fk_complaints_moderator" FOREIGN KEY ("id_moderator") REFERENCES "core"."users" ("id_user") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "core"."portfolio" ADD CONSTRAINT "fk_portfolio_user" FOREIGN KEY ("id_user") REFERENCES "core"."users" ("id_user") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "core"."audit_logs" ADD CONSTRAINT "fk_audit_logs_user" FOREIGN KEY ("user_id") REFERENCES "core"."users" ("id_user") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "core"."notifications" ADD CONSTRAINT "fk_notif_sender" FOREIGN KEY ("id_sender") REFERENCES "core"."users" ("id_user") ON DELETE CASCADE;

ALTER TABLE "core"."notifications" ADD CONSTRAINT "fk_notif_receiver" FOREIGN KEY ("id_receiver") REFERENCES "core"."users" ("id_user") ON DELETE CASCADE;

ALTER TABLE "core"."notifications" ADD CONSTRAINT "fk_notif_project" FOREIGN KEY ("id_project") REFERENCES "core"."projects" ("id_project") ON DELETE CASCADE;

ALTER TABLE "core"."warnings" ADD FOREIGN KEY ("id_user") REFERENCES "core"."users" ("id_user") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "core"."warnings" ADD FOREIGN KEY ("id_moderator") REFERENCES "core"."users" ("id_user") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "core"."warnings" ADD FOREIGN KEY ("id_complaint") REFERENCES "core"."complaints" ("id_complaint") ON DELETE SET NULL ON UPDATE CASCADE;
