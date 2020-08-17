provider "google" {
  credentials = file(var.key)
  project     = var.project_id
  region      = var.region
}
provider "google-beta" {
  credentials = file(var.key)
  project     = var.project_id
  region      = var.region
}

module "cloudsql" {
  source           = "./modules/cloudsql"
  network          = var.network
  db_version       = var.db_version
  db_instance_tier = var.db_instance_tier
  private_ip_name  = var.private_ip_name
  project_id       = var.project_id
  region           = var.region
}
/*
module "gke" {
  source           = "./modules/gke"
  cluster          = var.cluster_name
  network          = var.network
  project          = var.project_id
  region           = var.region
  subnetwork       = var.subnetwork
  zones            = ["${var.zone}"]
}
/*
module "memorystore" {
  source         = "./modules/memorystore"
  display_name   = var.redis_name
  ip_range       = "169.254.1.1/30"
  location       = var.zone
  name           = var.redis_name
  network        = var.network
  project        = var.project_id
  redis_version  = var.redis_version
  region         = var.region
  size           = var.redis_size
  tier           = var.redis_tier
}
*/
module "vpc" {
  source           = "./modules/vpc"
  project          = var.project_id
  network          = var.network
  region           = var.region
  subnetwork       = var.subnetwork
}
