# Trigger for application deployment to Cloud Run
resource "google_cloudbuild_trigger" "app_cicd_trigger" {
  project = var.project_id
  location = var.cb_region # CB has quote restrictions in certain regions
  name    = "deploy-${var.service_name}-svc"
  service_account = resource.google_service_account.cicd_runner_sa.id
  description = "Trigger for ${var.trigger_branch_name} application deployment"

  repository_event_config {
    repository = google_cloudbuildv2_repository.repo.id
    push {
      branch = "^${var.trigger_branch_name}$"
    }
  }

  filename = "deploy/cloudbuild.yaml"
  included_files = [
    "src/**",
    "tests/**",
  ]

  ignored_files   = ["README.md"]

  # Define substitutions - these override defaults in cloudbuild.yaml
  substitutions = {
    _DEPLOY_REGION                 = var.region
    _CB_REGION                     = var.cb_region
    _AR_HOSTNAME                   = "${var.cb_region}-docker.pkg.dev"
    _PLATFORM                      = "managed"
    _SERVICE_NAME                  = var.service_name
    _LOG_LEVEL                     = var.log_level
    _MAX_INSTANCES                 = "1"
    _CICD_RUNNER_SA_EMAIL           = "${var.cicd_runner_sa_name}@${var.project_id}.iam.gserviceaccount.com"
  }

  depends_on = [resource.google_project_service.apis, google_cloudbuildv2_repository.repo]

  tags = [
    var.service_name, 
    var.trigger_branch_name # Tag with the branch/environment
  ]

  lifecycle {
    # Prevent accidental deletion if the trigger is manually modified
    prevent_destroy = false # Set to true in production if desired
  }
}

# Trigger for infrastructure deployment using Terraform
resource "google_cloudbuild_trigger" "tf_trigger" {
  project         = var.project_id
  location        = var.cb_region # Trigger must be in the same region as the repo connection
  name            = "apply-terraform-infra"
  service_account = resource.google_service_account.cicd_runner_sa.id
  description     = "Trigger for ${var.trigger_branch_name} Terraform infrastructure deployment"

  repository_event_config {
    repository = google_cloudbuildv2_repository.repo.id
    push {
      branch = "^${var.trigger_branch_name}$"
    }
  }

  filename       = "deploy/cloudbuild-tf.yaml" # Point to the Terraform Cloud Build file
  included_files = [
    "deploy/**", # Trigger only on changes within the deploy directory
  ]

  ignored_files = ["README.md"] # Ignore other folders

  # Define substitutions required by cloudbuild-tf.yaml
  substitutions = {
    _TF_STATE_BUCKET              = "${var.project_id}-tfstate"
    _DEPLOY_REGION                = var.region
    _CB_REGION                    = var.cb_region
    _ORG                          = var.my_org
    _SERVICE_NAME                 = var.service_name
    _ARTIFACT_REPO_NAME           = var.artifact_repo_name
    _REPO_NAME                    = var.repository_name
    _REPO_OWNER                   = var.repository_owner
    _GITHUB_APP_INSTALLATION_ID   = var.github_app_installation_id
    _GITHUB_PAT_SECRET_ID         = var.github_pat_secret_id
    _BRANCH                       = var.trigger_branch_name
    _LOG_LEVEL                    = var.log_level
    _CICD_RUNNER_SA_EMAIL         = "${var.cicd_runner_sa_name}@${var.project_id}.iam.gserviceaccount.com"
  }

  depends_on = [resource.google_project_service.apis, google_cloudbuildv2_repository.repo]

  tags = [
    "terraform-managed",
    "infra-deployment",
    var.trigger_branch_name # Tag with the branch/environment
  ]

  lifecycle {
    prevent_destroy = false # Set to true in production if desired
  }
}