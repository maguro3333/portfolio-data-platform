terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # State is kept locally for this portfolio (gitignored). For a team setup this
  # would move to a GCS backend; documented as a design note, not used here.
}

provider "google" {
  project = var.project_id
  region  = var.region
}
