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

variable "sql_inst_name" {
  description = "SQL Jira instance"
}

variable "db_version" {
  description = "Database Version"
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
  description = "Private IP Name"
}
