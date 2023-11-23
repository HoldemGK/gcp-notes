provider "google" {
  credentials = "${file("${var.key}")}"
  project     = var.project
  region      = var.region
}

provider "google-beta" {
  credentials = "${file("${var.key}")}"
  project     = var.project
  region      = var.region
}