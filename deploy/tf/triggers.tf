# Trigger for app deployment using Terraform
resource "google_cloudbuild_trigger" "app_cicd_trigger" {
  project         = var.project_id
  location        = var.cb_region
  name            = "deploy-${var.service_name}-app"
  description     = "Deploy Cloud Run application on branch push"
  service_account = google_service_account.cicd_runner_sa.id

  # GitHub repo for the app
  github {
    owner = var.repository_owner
    name  = var.repository_name_app

    push {
      branch = "^${var.trigger_branch_name}$"
    }
  }

  # --------------------------
  # INLINE BUILD STEPS
  # --------------------------
  build {

    # 1. Build container
    step {
      id         = "Build Image"
      name       = "gcr.io/cloud-builders/docker"
      entrypoint = "sh"
      args = [
        "-c",
        <<-EOF
        docker build \
          -t ${var.cb_region}-docker.pkg.dev/${var.project_id}/${var.artifact_repo_name}/${var.service_name}:$SHORT_SHA \
          src/video-intelligence-streamlit
        EOF
      ]
    }

    # 2. Push image to Artifact Registry
    step {
      id   = "Push Image"
      name = "gcr.io/cloud-builders/docker"
      entrypoint = "sh"
      args = [
        "-c",
        <<-EOF
        docker push ${var.cb_region}-docker.pkg.dev/${var.project_id}/${var.artifact_repo_name}/${var.service_name}:$SHORT_SHA
        EOF
      ]
    }

    # 3. Deploy to Cloud Run
    step {
      id         = "Deploy to Cloud Run"
      name       = "gcr.io/google.com/cloudsdktool/cloud-sdk"
      entrypoint = "gcloud"
      args = [
        "run", "deploy", var.service_name,
        "--image=${var.cb_region}-docker.pkg.dev/${var.project_id}/${var.artifact_repo_name}/${var.service_name}:$SHORT_SHA",
        "--region=${var.region}",
        "--platform=managed",
        "--service-account=${var.cicd_runner_sa_name}@${var.project_id}.iam.gserviceaccount.com",
        "--allow-unauthenticated"
      ]
    }
  }

  tags = ["app", "cloud-run", var.trigger_branch_name]
}


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