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
  maintenance_start_time     = "05:00"
  remove_default_node_pool   = "true"

  node_pools = [
    {
      name               = join("-",[random_id.name_suffix.hex,"pool"])#${random_id.name_suffix.hex}"
      machine_type       = "n1-standard-2"
      min_count          = 1
      max_count          = 10
      local_ssd_count    = 0
      disk_size_gb       = 100
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
