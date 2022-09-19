resource "google_compute_instance" "mc-server" {
  name         = var.name
  machine_type = "e2-medium"
  zone         = var.zone

  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    foo = "bar"
  }

  metadata_startup_script = file("./scripts/startup.sh")

}