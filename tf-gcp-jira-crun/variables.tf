variable "project" {}

variable "key" {
  description = "The path to the GCP credentials JSON file"
}

variable "sql_inst_name" {
  description = "SQL Jira instance"
}

variable "region" {
  description = "In this example europe-west1"
}

variable "zone" {
  description = "In this example europe-west1-b"
}

variable "tier" {
  description = "The tier for the master instance."
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

variable "database_flags" {
  description = "The database flags for the master instance."
  type = list(object({
    name  = string
    value = string
  }))
  default = [{
    name = "character_set_server"
    value = "utf8mb4"
    }, {
    name = "sql_mode"
    value = "STRICT_TRANS_TABLES"
    }]
}

variable "root_password" {
  description = "MSSERVER password for the root user. If not set, a random one will be generated and available in the root_password output variable."
  default     = ""
}
