# https://app.terraform.io/app/gkllc/workspaces
terraform {
  cloud {
    organization = "gkllc"

    workspaces {
      name = "billing-control"
    }
  }
}

provider "google" {
  project     = var.project
  region      = var.region
  credentials = var.gcp-creds
}