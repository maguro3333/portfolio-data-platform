variable "project_id" {
  description = "GCP project ID for the EC portfolio data platform."
  type        = string
  default     = "psyched-camp-502314-m3"
}

variable "region" {
  description = "Default GCP region."
  type        = string
  default     = "asia-northeast1"
}

variable "location" {
  description = "Location for GCS buckets and BigQuery datasets (Tokyo)."
  type        = string
  default     = "asia-northeast1"
}

variable "environment" {
  description = "Environment label (dev for this portfolio)."
  type        = string
  default     = "dev"
}

# Logical data layers -> one BigQuery dataset each. Names match the dbt
# target datasets so the same models run locally (duckdb) and on BigQuery.
variable "bq_datasets" {
  description = "BigQuery datasets to create, keyed by logical layer."
  type        = map(string)
  default = {
    raw     = "ec_raw"
    staging = "ec_staging"
    core    = "ec_core"
    mart    = "ec_mart"
  }
}

variable "labels" {
  description = "Common labels applied to all resources for cost tracking."
  type        = map(string)
  default = {
    project    = "ec-portfolio"
    managed_by = "terraform"
  }
}
