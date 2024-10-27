resource "google_artifact_registry_repository" "proxyd" {
  provider      = google
  location      = var.region
  repository_id = "proxyd"
  description   = "Docker repository for proxyd"
  format        = "DOCKER"
}

# Set IAM policy to make the repository public
resource "google_artifact_registry_repository_iam_member" "public_access" {
  provider   = google
  location   = google_artifact_registry_repository.proxyd.location
  repository = google_artifact_registry_repository.proxyd.repository_id

  role   = "roles/artifactregistry.reader"
  member = "allUsers" # Public access
}

output "repository_url" {
  value = google_artifact_registry_repository.proxyd.id
}
