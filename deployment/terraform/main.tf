terraform {
    required_providers {
        google = {
            source  = "hashicorp/google"
            version = "~> 6.7"
        }
    }

    backend "gcs" {
        bucket = "d6c511449a9e8ced-terraform-remote-backend"
        prefix = "terraform/state"
    }
}

provider "google" {
  project     = var.project_id
  region      = var.region
}

module "state_bucket" {
  source = "./modules/state_bucket"
}

