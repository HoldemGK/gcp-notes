resource "google_compute_instance" "mc_server" {
  name         = "mc-server"
  machine_type = "e2-medium"
  zone         = "${var.region}-a"

  tags = ["minecraft-server"]

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  attached_disk = google_compute_disk.minecraft_disk.self_link

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

  service_account {
    scopes = ["default", "storage-rw"]
  }

}

resource "google_compute_disk" "minecraft_disk" {
  name  = "minecraft-disk"
  type  = "pd-ssd"
  physical_block_size_bytes = 50
}