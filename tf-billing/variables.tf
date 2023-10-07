variable "project" {
    type = string
    default = "billing-millenium-report"
}

variable "gcp-creds" {
    default= ""
}

variable "prefix" {
    type = string
    default = "gk"
}

variable "region" {
    type = string
    default = "europe-central2"
}
