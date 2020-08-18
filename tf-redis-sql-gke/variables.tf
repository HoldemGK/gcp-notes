variable "project_id" {}

variable "key" {
  description = "The path to the GCP credentials JSON file"
}

variable "region" {
  description = "In this example europe-west1"
}

variable "zone" {
  description = "In this example europe-west1-b"
}

variable "db_version" {
  description = "The database version"
}

variable "db_instance_tier" {
  description = "The database inst tier"
}

variable "network" {
  description = "Network Name"
}

variable "subnetwork" {
  description = "Subnetwork Name"
}

variable "private_ip_name" {
  description = "Private IP Name"
}

variable "cluster_name" {
  description = "Cluster Name"
}

variable "mce_start_time" {
  description = "maintenance_start_time"
}

variable "pool_machine_type" {
  description = "pool_machine_type"
}

variable "redis_name" {
  description = "Redis Name"
}

variable "redis_version" {
  description = "Redis Version"
}

variable "redis_size" {
  description = "Redis Size"
}

variable "redis_tier" {
  description = "Redis Tier"
}
