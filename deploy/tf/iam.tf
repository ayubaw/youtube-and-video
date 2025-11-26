# Configure IAM permissions for the project and Cloud Run service

data "google_project" "project" {
  project_id = var.project_id
}

# 1. Assign roles for the CICD project
resource "google_project_iam_member" "cicd_project_roles" {
  for_each = toset(local.roles)

  project    = var.project_id
  role       = each.value
  member     = "serviceAccount:${resource.google_service_account.cicd_runner_sa.email}"
  depends_on = [resource.google_project_service.apis] # Ensure APIs enabled
}

# 2. Grant Cloud Run SA the required permissions to run the application

# Special assignment: Allow the CICD SA to create tokens
resource "google_service_account_iam_member" "cicd_run_invoker_token_creator" {
  service_account_id = google_service_account.cicd_runner_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${resource.google_service_account.cicd_runner_sa.email}"
  depends_on         = [resource.google_project_service.apis]
}

# Special assignment: Allow the CICD SA to impersonate himself for trigger creation
resource "google_service_account_iam_member" "cicd_run_invoker_account_user" {
  service_account_id = google_service_account.cicd_runner_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${resource.google_service_account.cicd_runner_sa.email}"
  depends_on         = [resource.google_project_service.apis]
}

# Grant cicd-runner permission to actAs the Compute Engine default SA for Cloud Run deployments
# Amend for whatever SA we attach using --service-account when we deploy the Cloud Run service
resource "google_service_account_iam_member" "cicd_runner_actas_compute_sa" {
  # The service account we are granting permissions ON
  service_account_id = "projects/${var.project_id}/serviceAccounts/${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser" # The role being granted
  member             = "serviceAccount:${google_service_account.cicd_runner_sa.email}"
}

resource "google_secret_manager_secret_iam_binding" "cloudbuild_access" {
  project   = data.google_project.project.number
  secret_id = var.github_pat_secret_id
  role      = "roles/secretmanager.secretAccessor"

  members = [
    "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
  ]
}
