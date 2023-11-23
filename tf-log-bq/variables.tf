variable "prefix" {
}
variable "project" {
  default = ""
}
variable "key" {
  default = ""
}
variable "region" {
  default = "europe-north1"
}

variable "labels" {
  type        = map(string)
  description = "A set of key/value label pairs to assign to the resources deployed by this blueprint."
  default     = {}
}

variable "delete_contents_on_destroy" {
  type        = bool
  description = "If set to true, delete all BQ resources."
  default     = false
}

variable "services" {
  type        = list(string)
  default     = ["bigquery.googleapis.com",
                 "bigquerydatatransfer.googleapis.com"]
}

variable "filter_resource" {
  default = "gce_instance"
}