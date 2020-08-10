provider "google" {
  credentials = file(var.key)
  project     = var.project
  region      = var.region
}

resource "google_service_account" "service_account" {
  account_id   = var.sa_name
  display_name = var.sa_name
}

resource "google_project_iam_binding" "project" {
  project = var.project
  role    = var.sa_role

  members = ["serviceAccount:${var.sa_email}"]
}

resource "google_sql_database_instance" "sql_jira_inst" {
  name             = var.sql_inst_name
  database_version = "MYSQL_5_7"
  zone           = var.zone

  settings {
    character_set_server="utf8mb4"
    sql_mode="STRICT_TRANS_TABLES"
  }
}
