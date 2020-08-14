variable "database_version" {
  description = "The database version"
  default = "POSTGRES_11"
}

variable "network" {
  description = "The name of the network being created"
}

variable "private_ip_name" {
  description = "The name of the private ip address being created"
}

variable "project" {
  description = "Project ID"
}

variable "region" {
  description = "Region"
}

variable "user_name" {
  default     = "DB_USER"
}

variable "user_password" {
  default     = "DB_PASSWORD"
}
