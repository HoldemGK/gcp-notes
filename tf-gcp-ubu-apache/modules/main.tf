// Terraform plugin for creating random ids
resource "random_id" "instance_id" {
 byte_length = 8
}

data "google_compute_image" "ubuntu_image" {
	family  = var.family
	project = var.project
}

resource "google_compute_instance" "web-serv" {
    name = var.hostname
    machine_type = var.machine_type
    zone = var.zone

    boot_disk {
   initialize_params {
     image = "${data.google_compute_image.ubuntu_image.self_link}"
   }
 }

 metadata_startup_script = "${path.module}/install.sh"

 network_interface {
   network = "default"

   access_config {}
 }
 metadata = {
  sshKeys = "${var.gce_user}:${path.module}/id_rsa.pub"
  }
}
