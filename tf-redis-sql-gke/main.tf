locals {
  network          = var.network
  region           = var.region
  project_id       = "gk-storage"
  subnetwork       = var.subnetwork
}

// Configure the Google Cloud provider
provider "google" {
 credentials = file("/home/atos_holdemgk/key-tf.json")
 project     = local.project_id
 region      = local.region
}

provider "google-beta" {
  credentials = file("/home/atos_holdemgk/key-tf.json")
  project     = local.project_id
  region      = local.region
}

module "cloudsql" {
  source           = "./modules/cloudsql"
  database_version = var.database_version # "POSTGRES_11"
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
  zones            = ["us-west1-b", "us-west1-c"]
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
