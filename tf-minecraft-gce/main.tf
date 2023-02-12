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
    shutdown-script = file("./scripts/shutdown.sh")
  }

  metadata_startup_script = replace(coalesce(var.custom_user_data, templatefile("${path.module}/scripts/startup_script.tpl",
    {
      #INIT_URL   = var.INIT_URL,
      BUCKET_PREFIX = var.project,
      NETDATA_TOKEN = var.netdata_token
  })), "/\r/", "")


  service_account {
    scopes = ["storage-rw",
      "logging-write",
      "monitoring",
      "service-management",
      "service-control",
    "trace"]
  }
}

resource "google_compute_disk" "minecraft_disk" {
  name = "minecraft-disk"
  zone = local.zone
  #type = "pd-ssd"
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