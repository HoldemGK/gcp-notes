terraform {
  required_version = ">= 0.12.26"
}

provider "google" {
  region = "us-east1"
}

resource "google_compute_instance" "example" {
  name         = "server"
  machine_type = "f1-micro"
  zone         = "us-east1-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }
}

variable "instance_name" {
  description = "The Name to use for the Cloud Instance."
  default     = "gcp-hello-world-example"
}
