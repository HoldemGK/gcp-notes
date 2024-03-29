terraform {
  cloud {
    organization = "gkllc"

    workspaces {
      name = "tf-minecraft-gce"
    }
  }
}

provider "google" {
  project     = var.project
  region      = var.region
  credentials = file(var.key_json)
}