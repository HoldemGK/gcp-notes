terraform {
  required_version = ">= 0.12.7"

  required_providers {
    google = ">= 3.4"
  }
}
terraform {
  backend "gcs" {
    bucket = var.back_backet
    prefix = var.prefix
  }
}

# Deploy a Google Source Repo
resource "google_sourcerepo_repository" "repo" {
  name = var.repository_name
  project = var.project
}

# Deploy a Cloud Run service
resource "google_cloud_run_service" "service" {
  name = var.service_name
  location = var.location
  project = var.project

  template {
    metadata {
      annotations = {
        "client.knative.dev/user-image" = var.image_name
        "run.googleapis.com/cloudsql-instances" = local.instance_connection_name
        "run.googleapis.com/client-name" = "gcloud"
        "run.googleapis.com/" = "all"
        "run.googleapis.com/" = "all"
        "run.googleapis.com/" = "336.0.0"
      }
    }

    spec {
      containers {
        image = var.image_name
        ports {
          container_port = var.container_port
        }
        env {
          name = "CLOUDPROV"
          value = "GCP"
        }
        env {
          name = "INSTANCE_CONNECTION_NAME"
          value = local.instance_connection_name
        }
        env {
          name = "DBHOST"
          value = var.db_instance_name
        }
        env {
          name = "DBNAME"
          value = var.db_name
        }
        env {
          name = "DBUSER"
          value = var.db_username
        }
        env {
          name = "DBPASSWORD"
          value = data.google_secret_manager_secret_version.my-secret.secret_data
        }
      }
    }
  }

  traffic {
    percent = 100
    latest_revision = true
  }
  depends_on = [google_sql_database.default]
}

# Expose the Service Publically
resource "google_cloud_run_service_iam_member" "allUser" {
  service = google_cloud_run_service.service.name
  location = google_cloud_run_service.service.location
  project = var.project
  role = "roles/run.invoker"
  member = "allUser"
}

data "google_secret_manager_secret_version" "my-secret" {
  provider = google
  project = var.project
  secret = var.db_password
  version = "1"
}

# Create a Cloud Build Trigger
resource "google_cloudbuild_trigger" "cloud_build_trigger" {
  description = "Cloud Source Repository Trigger ${var.repository_name} (${var.branch_name})"
  project = var.project
  trigger_template {
    branch_name = var.branch_name
    repo_name = var.repository_name
  }
  build {
    images = ["gcr.io/$PROJECT/$REPO_NAME:latest"]
    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["build", "-t", "gcr.io/$PROJECT/$REPO_NAME:latest", "-f", "Dockerfile", "."]
    }
    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["push", "gcr.io/$PROJECT/$REPO_NAME:latest"]
    }
    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = ["run", "deploy", google_cloud_run_service.service.name,
           "--platform", "managed", "--region", var.location,
           "--image", var.image_name, "--allow-unauthenticated", "--port", "80",
           "--set-env-vars", "CLOUDPROV=${var.cloud_provider},
           INSTANCE_CONNECTION_NAME=${local.instance_connection_name},
           DBHOST=${var.db_instance_name}, DBNAME=${var.db_name},
           DBUSER=${var.db_username},
           DBPASSWORD=${data.google_secret_manager_secret_version.my-secret.secret_data}"]
    }
  }
}

# Deploy a Database
resource "google_sql_database_instance" "master" {
  name = var.db_instance_name
  region = var.location
  database_version = "MYSQL_5_7"
  project = var.project
  settings {
    tier = var.db_tier
  }
  deletion_protection = false
}

resource "google_sql_database" "default" {
  name = var.db_name
  project = var.project
  instance = google_sql_database_instance.master.name

  depends_on = [google_sql_database_instance.master]
}

resource "google_sql_user" "default" {
  project = var.project
  name = var.db_username
  instance = google_sql_database_instance.master.name
  host = var.db_user_host
  password = data.google_secret_manager_secret_version.my-secret.secret_data

  depends_on = [google_sql_database.default]
}

# Prepare locals
locals {
  image_name = var.image_name == "" ? "gcr.io/${var.project}/${var.service_name}" : var.image_name
  instance_connection_name = "${var.project}:${var.location}:${var.db_instance_name}"
}
