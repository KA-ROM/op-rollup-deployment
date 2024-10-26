resource "google_storage_bucket" "genesis_bucket" {
  name          = "op-geth-genesis-bucket"
  location      = "EU"
  force_destroy = true 

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365  
    }
  }
}

resource "google_storage_bucket_object" "genesis_file" {
  name   = "genesis.json"
  bucket = google_storage_bucket.genesis_bucket.name
  source = "./files/genesis.json"
}

resource "google_storage_bucket_iam_member" "public_access" {
  bucket = google_storage_bucket.genesis_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}