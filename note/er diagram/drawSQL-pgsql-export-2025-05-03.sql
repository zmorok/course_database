CREATE TABLE "notifications"(
    "id_notification" SERIAL NOT NULL,
    "id_sender" INTEGER NOT NULL,
    "id_receiver" INTEGER NOT NULL,
    "id_project" INTEGER NOT NULL,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL
);
ALTER TABLE
    "notifications" ADD PRIMARY KEY("id_notification");
CREATE TABLE "audit_logs"(
    "id_log" SERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "proc_name" VARCHAR(100) NOT NULL,
    "action" VARCHAR(10) NOT NULL,
    "table_name" VARCHAR(50) NOT NULL,
    "record_id" INTEGER NOT NULL,
    "old_data" jsonb NULL,
    "new_data" jsonb NULL,
    "changed_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL
);
ALTER TABLE
    "audit_logs" ADD PRIMARY KEY("id_log");
CREATE TABLE "portfolio"(
    "id_portfolio" SERIAL NOT NULL,
    "id_user" INTEGER NOT NULL,
    "description" TEXT NOT NULL,
    "media" jsonb NOT NULL,
    "skills" TEXT NOT NULL,
    "experience" TEXT NOT NULL
);
ALTER TABLE
    "portfolio" ADD PRIMARY KEY("id_portfolio");
CREATE TABLE "warnings"(
    "id_warning" SERIAL NOT NULL,
    "id_user" INTEGER NOT NULL,
    "id_moderator" INTEGER NOT NULL,
    "id_complaint" INTEGER NOT NULL,
    "id_project" INTEGER NOT NULL,
    "message" TEXT NOT NULL,
    "issued_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "expires_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "is_resolved" BOOLEAN NOT NULL
);
ALTER TABLE
    "warnings" ADD PRIMARY KEY("id_warning");
CREATE TABLE "complaints"(
    "id_complaint" SERIAL NOT NULL,
    "id_user" INTEGER NOT NULL,
    "filed_by" INTEGER NOT NULL,
    "id_project" INTEGER NOT NULL,
    "id_moderator" INTEGER NOT NULL,
    "status" VARCHAR(50) NOT NULL,
    "description" TEXT NOT NULL,
    "media" jsonb NOT NULL
);
ALTER TABLE
    "complaints" ADD PRIMARY KEY("id_complaint");
CREATE TABLE "orders_archive"(
    "id_order_arc" SERIAL NOT NULL,
    "id_order" INTEGER NOT NULL,
    "id_project" INTEGER NOT NULL,
    "project_title" TEXT NOT NULL,
    "id_customer" INTEGER NOT NULL,
    "id_freelancer" INTEGER NOT NULL,
    "status" INTEGER NOT NULL,
    "creation_date" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "deadline" DATE NOT NULL
);
ALTER TABLE
    "orders_archive" ADD PRIMARY KEY("id_order_arc");
CREATE TABLE "orders"(
    "id_order" SERIAL NOT NULL,
    "id_project" INTEGER NOT NULL,
    "id_freelancer" INTEGER NOT NULL,
    "status" VARCHAR(50) NOT NULL,
    "creation_date" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deadline" DATE NOT NULL
);
ALTER TABLE
    "orders" ADD PRIMARY KEY("id_order");
CREATE TABLE "reviews"(
    "id_review" SERIAL NOT NULL,
    "id_author" INTEGER NOT NULL,
    "id_recipient" INTEGER NOT NULL,
    "comment" TEXT NOT NULL,
    "rating" INTEGER NOT NULL,
    "media" jsonb NOT NULL
);
ALTER TABLE
    "reviews" ADD PRIMARY KEY("id_review");
COMMENT
ON COLUMN
    "reviews"."rating" IS 'check (rating between 1 and 5)';
CREATE TABLE "projects"(
    "id_project" SERIAL NOT NULL,
    "id_customer" INTEGER NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "status" VARCHAR(50) NULL,
    "description" TEXT NULL,
    "media" jsonb NULL
);
ALTER TABLE
    "projects" ADD PRIMARY KEY("id_project");
CREATE TABLE "roles"(
    "id_role" SERIAL NOT NULL,
    "role_name" VARCHAR(50) NOT NULL,
    "role_privileges" jsonb NOT NULL
);
ALTER TABLE
    "roles" ADD PRIMARY KEY("id_role");
CREATE TABLE "users"(
    "id_user" SERIAL NOT NULL,
    "password" CHAR(128) NOT NULL,
    "role" INTEGER NOT NULL,
    "last_name" VARCHAR(100) NOT NULL,
    "first_name" VARCHAR(100) NOT NULL,
    "middle_name" VARCHAR(100) NOT NULL,
    "gender" VARCHAR(10) NOT NULL,
    "phone_number" VARCHAR(20) NOT NULL,
    "email" VARCHAR(100) NOT NULL,
    "registration_date" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "last_online_time" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "rating" DECIMAL(2, 1) NOT NULL
);
ALTER TABLE
    "users" ADD PRIMARY KEY("id_user");
ALTER TABLE
    "users" ADD CONSTRAINT "users_email_unique" UNIQUE("email");
ALTER TABLE
    "warnings" ADD CONSTRAINT "warnings_id_user_foreign" FOREIGN KEY("id_user") REFERENCES "users"("id_user");
ALTER TABLE
    "notifications" ADD CONSTRAINT "notifications_id_sender_foreign" FOREIGN KEY("id_sender") REFERENCES "users"("id_user");
ALTER TABLE
    "complaints" ADD CONSTRAINT "complaints_id_project_foreign" FOREIGN KEY("id_project") REFERENCES "projects"("id_project");
ALTER TABLE
    "reviews" ADD CONSTRAINT "reviews_id_author_foreign" FOREIGN KEY("id_author") REFERENCES "users"("id_user");
ALTER TABLE
    "orders" ADD CONSTRAINT "orders_id_project_foreign" FOREIGN KEY("id_project") REFERENCES "projects"("id_project");
ALTER TABLE
    "audit_logs" ADD CONSTRAINT "audit_logs_user_id_foreign" FOREIGN KEY("user_id") REFERENCES "users"("id_user");
ALTER TABLE
    "warnings" ADD CONSTRAINT "warnings_id_project_foreign" FOREIGN KEY("id_project") REFERENCES "projects"("id_project");
ALTER TABLE
    "orders_archive" ADD CONSTRAINT "orders_archive_id_customer_foreign" FOREIGN KEY("id_customer") REFERENCES "users"("id_user");
ALTER TABLE
    "warnings" ADD CONSTRAINT "warnings_id_moderator_foreign" FOREIGN KEY("id_moderator") REFERENCES "users"("id_user");
ALTER TABLE
    "complaints" ADD CONSTRAINT "complaints_filed_by_foreign" FOREIGN KEY("filed_by") REFERENCES "users"("id_user");
ALTER TABLE
    "users" ADD CONSTRAINT "users_role_foreign" FOREIGN KEY("role") REFERENCES "roles"("id_role");
ALTER TABLE
    "orders_archive" ADD CONSTRAINT "orders_archive_id_freelancer_foreign" FOREIGN KEY("id_freelancer") REFERENCES "users"("id_user");
ALTER TABLE
    "complaints" ADD CONSTRAINT "complaints_id_moderator_foreign" FOREIGN KEY("id_moderator") REFERENCES "users"("id_user");
ALTER TABLE
    "reviews" ADD CONSTRAINT "reviews_id_recipient_foreign" FOREIGN KEY("id_recipient") REFERENCES "users"("id_user");
ALTER TABLE
    "notifications" ADD CONSTRAINT "notifications_id_receiver_foreign" FOREIGN KEY("id_receiver") REFERENCES "users"("id_user");
ALTER TABLE
    "complaints" ADD CONSTRAINT "complaints_id_user_foreign" FOREIGN KEY("id_user") REFERENCES "users"("id_user");
ALTER TABLE
    "notifications" ADD CONSTRAINT "notifications_id_project_foreign" FOREIGN KEY("id_project") REFERENCES "projects"("id_project");
ALTER TABLE
    "portfolio" ADD CONSTRAINT "portfolio_id_user_foreign" FOREIGN KEY("id_user") REFERENCES "users"("id_user");
ALTER TABLE
    "orders" ADD CONSTRAINT "orders_id_freelancer_foreign" FOREIGN KEY("id_freelancer") REFERENCES "users"("id_user");
ALTER TABLE
    "projects" ADD CONSTRAINT "projects_id_customer_foreign" FOREIGN KEY("id_customer") REFERENCES "users"("id_user");
ALTER TABLE
    "warnings" ADD CONSTRAINT "warnings_id_complaint_foreign" FOREIGN KEY("id_complaint") REFERENCES "complaints"("id_complaint");