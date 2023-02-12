variable "project" {
  description = "The project to deploy to, if not set the default provider project is used."
}

variable "key_json" {
  default = ""
}

variable "region" {
  description = "Region for cloud resources"
  default     = "us-central1"
}

variable "name" {
  default = "mc-server"
}

variable "image" {
  default = "debian-cloud/debian-11"
}

variable "location" {
  default = "US"
}

variable "bucket_names" {
  type    = list(string)
  default = ["minecraft-backup", "minecraft-scripts"]
}

variable "custom_user_data" {
  description = "Provide a custom bash script or cloud-init script the BIG-IP will run on creation"
  type        = string
  default     = null
}

variable "netdata_token" {
  description = "Provide a token for monitoring system"
  type        = string
  default     = ""
}