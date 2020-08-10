/**
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

terraform {
  required_version = "~> 0.12.0"
}

resource "random_id" "instance_id" {
  byte_length = 8
}

data "google_compute_image" "centos_image" {
	family  = "centos-7"
	project = "centos-cloud"
}

resource "google_compute_instance" "redis_inst" {
  name         = "vm-${random_id.instance_id.hex}"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"

  boot_disk {
    initialize_params {
      image = "${data.google_compute_image.centos_image.self_link}"
    }
  }

  metadata_startup_script = "${path.module}/scripts/install.sh"

  tags = ["${var.target_tags}"]

  network_interface {
    network = "${var.network_name}"

    access_config {}
  }
}

resource "google_compute_firewall" "firewall_redis" {
  name = "allow-redis-default"

  network = "${var.network_name}"

  allow {
    protocol = "${lower(var.ip_protocol)}"
    ports    = ["${var.port}"]
  }

  source_ranges = ["${var.source_ranges}"]

  target_tags = ["${var.target_tags}"]
}


