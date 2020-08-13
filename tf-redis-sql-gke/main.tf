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
  private_ip_name  = var.private_ip_name
  project          = var.project_id
  region           = var.region
}

module "gke" {
  source           = "./modules/gke"
  cluster          = var.cluster_name
  network          = var.network
  project          = var.project_id
  region           = var.region
  subnetwork       = var.subnetwork
  zones            = ["${var.zone}"]
}
