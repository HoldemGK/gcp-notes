locals {
  zone = "${var.region}-a"
}

resource "google_compute_instance" "mc_server" {
  name         = "mc-server"
  machine_type = "e2-medium"
  zone         = local.zone

  tags = ["minecraft-server"]

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  attached_disk {
    source = google_compute_disk.minecraft_disk.self_link
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.mc_server_ip.address
    }
  }

  metadata = {
    startup-script  = file("./scripts/startup.sh")
    shutdown-script = file("./scripts/shutdown.sh")
  }

  #metadata_startup_script = file("./scripts/first_start.sh")


  service_account {
    scopes = ["storage-rw",
              "logging-write",
              "monitoring",
              "service-management",
              "service-control",
              "trace"]
  }

  provisioner "file" {
    source      = "./scripts/backup.sh"
    destination = "/home/minecraft/"
  }

  provisioner "remote-exec" {
    inline = [
      "export YOUR_BUCKET_NAME=${var.project}",
      "sudo chmod 755 /home/minecraft/backup.sh",
      "{ crontab -l; echo '0 */4 * * * /home/minecraft/backup.sh'; } | crontab -",
    ]
  }

}

resource "google_compute_disk" "minecraft_disk" {
  name = "minecraft-disk"
  zone = local.zone
  type = "pd-ssd"
  size = 50
}

resource "google_compute_address" "mc_server_ip" {
  name = "mc-server-ip"
}

resource "google_compute_firewall" "minecraft_rule" {
  name    = "minecraft-rule"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["25565"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["minecraft-server"]
}

resource "google_storage_bucket" "minecraft_buckets" {
  for_each      = toset(var.bucket_names)
  name          = "${var.project}-${each.value}"
  location      = var.location
  force_destroy = true
}