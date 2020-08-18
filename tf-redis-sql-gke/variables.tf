# GCP variables

variable "project" {}

variable "region" {
  description = "Region"
}

variable "subnetwork" {
  description = "subnetwork"
}

variable "network" {
  description = "network"
}

variable "database_version" {
  description = "The database version"
}

variable "cluster_name" {
  description = "cluster_name"
}
