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
