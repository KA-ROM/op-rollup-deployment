data "google_client_config" "default" {}

module "gke" {
  version                    = "~> 33.1"
  depends_on                 = [module.vpc]
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = var.project_id
  name                       = "${var.name_prefix}-gke-cluster"
  region                     = var.region
  network                    = module.vpc.network_name
  subnetwork                 = "${var.name_prefix}-public"  # Use the public subnet for the GKE cluster

  http_load_balancing        = true
  network_policy             = true
  horizontal_pod_autoscaling = true

  # Reference the names of the secondary IP ranges defined in the VPC module for the public subnet
  ip_range_pods              = "${var.name_prefix}-range-pods-public"  
  ip_range_services          = "${var.name_prefix}-range-services-public"

  # Default Node Pool Configuration
  node_pools = [
    {
      name            = "default-node-pool"
      machine_type    = "e2-small"
      node_locations  = "${var.region}-a,${var.region}-b"
      min_count       = 1
      max_count       = 5
      disk_size_gb    = 10
      disk_type       = "pd-standard"
      image_type      = "COS_CONTAINERD"
      auto_repair     = true
      auto_upgrade    = true

      create_service_account  = true
    }
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  node_pools_labels = {
    all = {
      service = "op-stack"
    }

    default-node-pool = {
      "default-node-pool" = true
      service             = "op-stack"
    }
  }

  node_pools_tags = {
    all = ["op-stack"]
  }

  node_pools_metadata = {
    all = {}

    default-node-pool = {
      "node-pool-metadata-custom-value" = "my-node-pool"
    }
  }

  node_pools_taints = {
    all = []

    default-node-pool = [
      {
        key    = "default-node-pool"
        value  = "true"
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }
}
