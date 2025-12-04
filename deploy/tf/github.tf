# Cloud Build GitHub App Connection - We are still using Github PAT because terraform still expects it if
  #github_app_installation_id is used.
provider "github" {
  token = data.google_secret_manager_secret_version_access.github_token.secret_data
  owner = var.repository_owner
}

# Fetch the GitHub PAT secret
data "google_secret_manager_secret_version_access" "github_token" {
  secret = var.github_pat_secret_id
  depends_on = [resource.google_project_service.apis]
}

resource "google_cloudbuildv2_connection" "github_connection" {
  project  = var.project_id
  location = var.cb_region
  name     = "github-connection"

  github_config {
    app_installation_id = var.github_app_installation_id
    authorizer_credential {
      oauth_token_secret_version = data.google_secret_manager_secret_version_access.github_token.id
    }
  }
  depends_on = [resource.google_project_service.apis]
}

resource "google_cloudbuildv2_repository" "repo_iac" {
  project           = var.project_id
  location          = var.cb_region
  name              = var.repository_name
  parent_connection = google_cloudbuildv2_connection.github_connection.id
  remote_uri        = "https://github.com/${var.repository_owner}/${var.repository_name}.git"

  depends_on = [google_project_service.apis]
}

resource "google_cloudbuildv2_repository" "repo_app" {
  project           = var.project_id
  location          = var.cb_region
  name              = var.repository_name_app
  parent_connection = google_cloudbuildv2_connection.github_connection.id
  remote_uri        = "https://github.com/${var.repository_owner}/${var.repository_name_app}.git"

  depends_on = [google_project_service.apis]
}
