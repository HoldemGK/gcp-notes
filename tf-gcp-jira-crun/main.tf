provider "google" {
  credentials = file(var.key)
  project     = var.project
  region      = var.region
}

resource "google_service_account" "service_account" {
  account_id   = var.sa_name
  display_name = var.sa_name
}

resource "google_project_iam_binding" "iam_binding" {
  project = var.project
  role    = var.sa_role

  members = ["serviceAccount:${var.sa_email}"]
}

resource "random_password" "root-password" {
  length  = 8
  special = true
}

resource "google_sql_database_instance" "sql_jira_inst" {
  name             = var.sql_inst_name
  database_version = "MYSQL_5_7"
  region           = var.region
  root_password = coalesce(var.root_password, random_password.root-password.result)

  settings {
    tier = var.tier
    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = lookup(database_flags.value, "name", null)
        value = lookup(database_flags.value, "value", null)
      }
    }
  }
}

resource "google_cloud_run_service" "jira-crun" {
  name     = "cloudrun-srv"
  location = var.region

  template {
    spec {
      containers {
        image = var.gcr_image
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"      = "1000"
        "run.googleapis.com/cloudsql-instances" = "my-project-name:us-central1:${google_sql_database_instance.instance.name}"
        "run.googleapis.com/client-name"        = "terraform"
      }
    }
  }
  autogenerate_revision_name = true
}
