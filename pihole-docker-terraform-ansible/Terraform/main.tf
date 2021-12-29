# =================== #
# Deploying VMware VM #
# =================== #
terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "2.0.2"
    }
  }
  backend "remote" {
    organization = "HashiCorp-Sam"
    token        = TFC_TOKEN

    workspaces {
      name = "pihole-docker-vsphere"
    }
  }
}

# Connect to VMware vSphere vCenter
provider "vsphere" {
  vim_keep_alive = 30
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = var.vsphere-unverified-ssl
}

# Docker VM
module "vsphere_vm-public" {
  for_each               = var.worker_nodes
  source                 = "app.terraform.io/HashiCorp-Sam/vsphere_vm-public/vsphere"
  version                = "1.0.1"
  vsphere_user           = var.vsphere_user
  vsphere_password       = var.vsphere_password
  vsphere_vcenter        = var.vsphere_server
  ssh_username           = var.ssh_username
  name                   = each.key
  cpu                    = var.worker_cpu
  cores-per-socket       = var.worker_cores-per-socket
  ram                    = var.worker_ram
  disksize               = var.worker_disksize
  vm-template-name       = var.vm-template-name
  vm-guest-id            = var.vm-guest-id
  vsphere-unverified-ssl = var.vsphere-unverified-ssl
  vsphere-datacenter     = var.vsphere-datacenter
  vsphere-cluster        = var.vsphere-cluster
  vm-datastore           = var.vm-datastore
  vm-network             = var.vm-network
  vm-domain              = var.vm-domain
  dns_server_list        = var.dns_server_list
  ipv4_address           = each.value
  ipv4_gateway           = var.ipv4_gateway
  ipv4_netmask           = var.ipv4_netmask
  public_key             = var.public_key
}
