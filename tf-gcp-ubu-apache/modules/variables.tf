variable "hostname" {
  description = "Hostname of instances"
  type        = string
}

variable "gce_user" {
  description = "Ubuntu user"
  default     = "$USER"
}

variable "zone" {
  description = "Zone of instances"
  default     = "europe-north1-a"
}

variable "machine_type" {
  description = "Machine type of instances"
  default     = "f1-micro"
}

variable "family" {
  description = "Family of instances"
  default     = "ubuntu-1804-lts"
}

variable "project" {
  description = "Project of family"
  default     = "ubuntu-os-cloud"
}
