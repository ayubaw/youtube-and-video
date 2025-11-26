
resource "google_service_account" "cicd_runner_sa" {
  account_id   = var.cicd_runner_sa_name
  display_name = "CICD Runner SA"
  project      = var.project_id
  depends_on   = [resource.google_project_service.apis]
}
