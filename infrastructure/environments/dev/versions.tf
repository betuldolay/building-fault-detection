terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.0"
    }
  }

  # State is shared by the team and by GitLab CI, so it lives in a bucket, not on a laptop.
  # Left commented out so `terraform init` and `validate` work without a GCP account.
  # backend "gcs" {
  #   bucket = "<project>-terraform-state"
  #   prefix = "fault-detection/dev"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
