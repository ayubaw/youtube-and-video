# Create Artifact Registry repository for Docker images

resource "google_artifact_registry_repository" "repo" {
  project       = var.project_id
  location      = var.cb_region
  repository_id = var.service_name
  description   = "Image repository application"
  format        = "DOCKER"

  depends_on = [resource.google_project_service.apis]
}
