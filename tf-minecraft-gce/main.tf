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
      nat_ip = google_compute_address.mc_server_ip
    }
  }

  metadata = {
    startup-script-url  = "https://storage.googleapis.com/cloud-training/archinfra/mcserver/startup.sh"
    shutdown-script-url = "https://storage.googleapis.com/cloud-training/archinfra/mcserver/shutdown.sh"
  }

  metadata_startup_script = file("./scripts/first_start.sh")
  

  service_account {
    scopes = ["default", "storage-rw"]
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
  name  = "minecraft-disk"
  type  = "pd-ssd"
  physical_block_size_bytes = 50
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

resource "google_storage_bucket" "minecraft_backup" {
  name          = "${var.project}-minecraft-backup"
  location      = "US"
  force_destroy = true
}