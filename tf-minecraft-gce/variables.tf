variable "project" {
  description = "The project to deploy to, if not set the default provider project is used."
  default     = ""
}

variable "gcp-creds" {
default= ""
}

variable "region" {
  description = "Region for cloud resources"
  default     = "us-central1"
}

variable "name" {
  default     = "mc-server"
}

variable "image" {
  default     = "debian-cloud/debian-11"
}