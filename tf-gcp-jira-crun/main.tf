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
  depends_on = [google_service_account.service_account]
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

  provisioner "local-exec" {
    command = "./up_gcr_image.sh"
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
        "run.googleapis.com/cloudsql-instances" = "${var.project}:${var.region}:${google_sql_database_instance.sql_jira_inst.name}"
        "run.googleapis.com/client-name"        = "terraform"
      }
    }
  }
  autogenerate_revision_name = true

  depends_on = [google_sql_database_instance.sql_jira_inst]
}

# Create public access
data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}
# Enable public access on Cloud Run service
resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.jira-crun.location
  project     = google_cloud_run_service.jira-crun.project
  service     = google_cloud_run_service.jira-crun.name
  policy_data = data.google_iam_policy.noauth.policy_data
}
