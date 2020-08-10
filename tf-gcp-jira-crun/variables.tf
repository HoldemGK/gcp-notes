variable "project" {}

variable "key" {
  description = "The path to the GCP credentials JSON file"
}

variable "sql_inst_name" {
  description = "SQL Jira instance"
}

variable "num_instances" {
  description = "Number of instances to create"
}

variable "region" {
  description = "In this example europe-west1"
}

variable "zone" {
  description = "In this example europe-west1-b"
}

variable "machine_type" {
  description = "Type of instance"
}

variable "sa_name" {
  description = "Service account Name"
}

variable "sa_role" {
  description = "Service account Role"
}

variable "sa_email" {
  description = "Service account Email"
}

variable "image_family" {
  description = "GCP image family"
}
