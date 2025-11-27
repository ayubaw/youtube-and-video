# Input variables for the Terraform configuration

variable "project_id" {
  description = "The Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "The Google Cloud region for deployment."
  type        = string
  default     = "europe-west2"
}

variable "cb_region" {
  description = "The Google Cloud region where Cloud Build will run."
  type        = string
  default     = "europe-west2"
}

variable "my_org" {
  description = "Your organization's domain (e.g., example.com)."
  type        = string
}

variable "cicd_runner_sa_name" {
  description = "Service account name to be used for the CICD processes"
  type        = string
  default     = "cicd-runner"
}

variable "repository_name" {
  description = "Name of the GitHub repository you'd like to connect to Cloud Build"
  type        = string
}

variable "repository_owner" {
  description = "Owner of the GitHub repository"
  type        = string
}

# Retrieve this from the GitHub App settings, and then retrieve from the URL
# E.g. https://github.com/settings/installations/12345678
variable "github_app_installation_id" {
  description = "GitHub App Installation ID (e.g. 12345678)"
  type        = string
}

# E.g. github-connection-github-oauthtoken-218621
variable "github_pat_secret_id" {
  description = "GitHub PAT secret id in Cloud Secret Manager"
  type        = string
  default     = "github-pat"
}

variable "service_name" {
  description = "The name for the Cloud Run service and related resources."
  type        = string
  default     = "video-intelligence"
}

variable "log_level" {
  description = "Logging level."
  type        = string
  default     = "DEBUG"
}

variable "connection_exists" {
  description = "Flag indicating if a Cloud Build connection already exists"
  type        = bool
  default     = false
}

variable "artifact_repo_name" {
  description = "The name for the Artifact Registry repository."
  type        = string
  default     = "video-intelligence" # Matches the service name by default
}

variable "trigger_branch_name" {
  description = "The git branch name that should activate this trigger."
  type        = string
#   default     = "dev" # Default might be dev, override for main
}

variable "repository_name_app" {
  description = "The name of the application repository"
  type        = string
#   default     = "YV-app" # Default might be dev, override for main
}
