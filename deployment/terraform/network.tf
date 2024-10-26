module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 9.3"

  project_id   = var.project_id
  network_name = "${var.name_prefix}-vpc"
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name               = "${var.name_prefix}-private"
      subnet_ip                 = "10.10.10.0/24"
      subnet_region             = var.region
      subnet_private_access     = true
      subnet_flow_logs          = true
    },
    {
      subnet_name               = "${var.name_prefix}-public"
      subnet_ip                 = "10.10.20.0/24"
      subnet_region             = var.region
      subnet_private_access     = false
      subnet_flow_logs          = true
    }
  ]

  # Define secondary ranges for each subnet
  secondary_ranges = {
    "${var.name_prefix}-private" = [
      {
        range_name    = "${var.name_prefix}-range-pods-private-nat"
        ip_cidr_range = "10.20.0.0/16"
      },
      {
        range_name    = "${var.name_prefix}-range-services-private-nat"
        ip_cidr_range = "10.30.0.0/20"
      }
    ],

    # For the public subnet, ranges for Pods and Services
    "${var.name_prefix}-public" = [
      {
        range_name    = "${var.name_prefix}-range-pods-public"
        ip_cidr_range = "10.40.0.0/16"
      },
      {
        range_name    = "${var.name_prefix}-range-services-public"
        ip_cidr_range = "10.50.0.0/20"
      }
    ]
  }
}

# Cloud NAT for private nodes to access the internet
resource "google_compute_router" "nat_router" {
  name    = "${var.name_prefix}-nat-router"
  region  = var.region
  network = module.vpc.network_name
}

resource "google_compute_router_nat" "nat_config" {
  name                       = "${var.name_prefix}-nat-config"
  router                     = google_compute_router.nat_router.name
  region                     = google_compute_router.nat_router.region
  nat_ip_allocate_option      = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = "projects/${var.project_id}/regions/${var.region}/subnetworks/${var.name_prefix}-private"
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  subnetwork {
    name                    = "projects/${var.project_id}/regions/${var.region}/subnetworks/${var.name_prefix}-public"
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Firewall rules for internal and external access
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.name_prefix}-allow-internal"
  network = module.vpc.network_name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"] 
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"] 
  }

  source_ranges = ["10.10.10.0/24", "10.10.20.0/24"]
}

resource "google_compute_firewall" "allow_lb_traffic" {
  name    = "${var.name_prefix}-allow-loadbalancer-traffic"
  network = module.vpc.network_name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

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
