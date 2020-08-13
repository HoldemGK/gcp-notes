locals {
  database_version = var.db_version # "POSTGRES_11"
  network          = "NET" # Network name
  region           = "" # us-east1
  project_id       = var.project_id # GCP Project ID
  subnetwork       = "SUBNET" # Subnetwork name
}

// Configure the Google Cloud provider
provider "google" {
 credentials = file(var.key)
 project     = local.project_id
 region      = local.region
}

provider "google-beta" {
  credentials = file(var.key)
  project     = local.project_id
  region      = local.region
}

module "cloudsql" {
  source           = "./modules/cloudsql"
  network          = local.network
  private_ip_name  = "" # Private IP Name
  project          = local.project_id
  region           = local.region
}

module "gke" {
  source           = "./modules/gke"
  cluster          = "" # Cluster Name
  network          = local.network
  project          = local.project_id
  region           = local.region
  subnetwork       = local.subnetwork
  zones            = "" # ["us-east1-b", "us-east1-c", "us-east1-d"]
}

module "memorystore" {
  source         = "./modules/memorystore"
  display_name   = "" # Display Name
  ip_range       = "" #
  location       = "" # Zone
  name           = "" # Instance name
  network        = local.network
  project        = local.project_id
  redis_version  = "" # 5.0
  region         = local.region
  size           = "" # 1
  tier           = "" # STANDARD
}

module "vpc" {
  source           = "./modules/vpc"
  project          = local.project_id
  network          = local.network
  region           = local.region
  subnetwork       = local.subnetwork
}
