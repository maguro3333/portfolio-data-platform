terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Local state for this portfolio (gitignored), mirroring the GCP stack.
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

data "aws_caller_identity" "current" {}
