# # Trigger for application deployment to Cloud Run
# resource "google_cloudbuild_trigger" "app_cicd_trigger" {
#   project = var.project_id
#   location = var.cb_region # CB has quote restrictions in certain regions
#   name    = "deploy-${var.service_name}-svc"
#   service_account = resource.google_service_account.cicd_runner_sa.id
#   description = "Trigger for ${var.trigger_branch_name} application deployment"
#
#   repository_event_config {
#     repository = google_cloudbuildv2_repository.repo_app.id
#     push {
#       branch = "^${var.trigger_branch_name}$"
#     }
#   }
#
#   filename = "cloudbuild.yaml"
#   included_files = [
#     "src/**",
#     "tests/**",
#   ]
#
#   ignored_files   = ["README.md"]
#
#   # Define substitutions - these override defaults in cloudbuild.yaml
#   substitutions = {
#     _DEPLOY_REGION                 = var.region
#     _CB_REGION                     = var.cb_region
#     _AR_HOSTNAME                   = "${var.cb_region}-docker.pkg.dev"
#     _PLATFORM                      = "managed"
#     _SERVICE_NAME                  = var.service_name
#     _LOG_LEVEL                     = var.log_level
#     _MAX_INSTANCES                 = "1"
#     _CICD_RUNNER_SA_EMAIL           = "${var.cicd_runner_sa_name}@${var.project_id}.iam.gserviceaccount.com"
#   }
#
#   depends_on = [resource.google_project_service.apis, google_cloudbuildv2_repository.repo_app]
#
#   tags = [
#     var.service_name,
#     var.trigger_branch_name # Tag with the branch/environment
#   ]
#
#   lifecycle {
#     # Prevent accidental deletion if the trigger is manually modified
#     prevent_destroy = false # Set to true in production if desired
#   }
# }

# Trigger for infrastructure deployment using Terraform
resource "google_cloudbuild_trigger" "tf_trigger" {
  project         = var.project_id
  location        = var.cb_region # Trigger must be in the same region as the repo connection
  name            = "apply-terraform-infra"
  service_account = resource.google_service_account.cicd_runner_sa.id
  description     = "Trigger for ${var.trigger_branch_name} Terraform infrastructure deployment"

  repository_event_config {
    repository = google_cloudbuildv2_repository.repo_iac.id
    push {
      branch = "^${var.trigger_branch_name}$"
    }
  }
  # INLINE BUILD STEPS (instead of cloudbuild-tf.yaml)
  build {
    step {
      id = "TF Init"
      name = "hashicorp/terraform:1.10"
      entrypoint = "sh"
      dir = "deploy/tf"
      args = ["-c", <<-EOF
        terraform init \
          -backend-config=bucket=${var.project_id}-tfstate \
          -backend-config=prefix=terraform/state/dev
        EOF
      ]
    }
    step {
      id = "TF Plan"
      name = "hashicorp/terraform:1.10"
      entrypoint = "sh"
      dir = "deploy/tf"
      args = ["-c", <<-EOF
        terraform plan \
          -var-file=vars/dev.tfvars \
          -out=tfplan
        EOF
      ]
    }
    step {
      id = "TF Apply"
      name = "hashicorp/terraform:1.10"
      entrypoint = "sh"
      dir = "deploy/tf"
      args = ["-c", "terraform apply -auto-approve tfplan"]
    }
  }

  tags = ["iac", "terraform"]
}