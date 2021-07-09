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
