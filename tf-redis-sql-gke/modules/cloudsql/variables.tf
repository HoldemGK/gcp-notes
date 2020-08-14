variable "project_id" {}

variable "db_version" {
  description = "The database version"
}

variable "db_instance_tier" {
  description = "The database inst tier"
}

variable "network" {
  description = "The name of the network being created"
}

variable "private_ip_name" {
  description = "The name of the private ip address being created"
}

variable "region" {
  description = "Region"
}

variable "purpose" {
  description = "private_ip_address"
  default     = "VPC_PEERING"
}

variable "address_type" {
  description = "private_ip_address"
  default     = "INTERNAL"
}

variable "prefix_length" {
  description = "private_ip_address"
  default     = 16
}

variable "user_name" {
  default     = "DB_USER"
}

variable "user_password" {
  description = "If not defined, generated random"
  default     = ""
}
