resource "random_id" "name_suffix" {
  byte_length = 4
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = var.project
  name                       = var.cluster_name
  region                     = var.region
  zones                      = var.zones
  network                    = var.network
  subnetwork                 = var.subnetwork
  ip_range_pods              = join("-",[var.subnetwork,"pods"])
  ip_range_services          = join("-",[var.subnetwork,"services"])
  http_load_balancing        = "true"
  horizontal_pod_autoscaling = "true"
  network_policy             = "true"
  maintenance_start_time     = var.mce_start_time
  remove_default_node_pool   = "true"

  node_pools = [
    {
      name               = "pool-def"
      machine_type       = var.pool_machine_type
      min_count          = var.min_count
      max_count          = var.max_count
      local_ssd_count    = 0
      disk_size_gb       = var.disk_size_gb
      disk_type          = "pd-standard"
      image_type         = "COS"
      auto_repair        = "true"
      auto_upgrade       = "true"
      preemptible        = "true"
      initial_node_count = 2
    }
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  node_pools_labels = {
    all = {}

  }

  node_pools_metadata = {
    all = {}

  }

  node_pools_tags = {
    all = []

  }
}
