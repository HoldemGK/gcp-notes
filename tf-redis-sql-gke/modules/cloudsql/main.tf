locals {
  network          = join("/", ["projects", var.project_id, "global", "networks", var.network])
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "random_password" "user_password" {
  length  = 8
  special = true
}

resource "google_compute_global_address" "private_ip_address" {
  provider = google-beta

  name          = var.private_ip_name
  purpose       = var.purpose
  address_type  = var.address_type
  prefix_length = var.prefix_length
  network       = local.network
  depends_on    = [local.network]
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta

  network                 = local.network
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
  depends_on              = [local.network]
}

resource "google_sql_database_instance" "instance" {
  provider = google-beta

  name   = "private-instance-${random_id.db_name_suffix.hex}"
  database_version = var.db_version
  region = var.region

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = var.db_instance_tier
    ip_configuration {
      ipv4_enabled    = false
      private_network = local.network
    }
  }
}

resource "google_sql_user" "users" {
  name     = var.user_name
  instance = google_sql_database_instance.instance.name
  password = coalesce(var.user_password, random_password.user_password.result)
}
