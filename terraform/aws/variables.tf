variable "region" {
  description = "AWS region (Tokyo, matching the GCP stack)."
  type        = string
  default     = "ap-northeast-1"
}

variable "project_prefix" {
  description = "Prefix for globally-unique resource names."
  type        = string
  default     = "ec-portfolio"
}

# Glue Data Catalog databases = Athena schemas, mirroring the BigQuery datasets
# and the dbt layer routing (intermediate -> ec_core, marts -> ec_mart).
variable "glue_databases" {
  description = "Glue catalog databases to create, keyed by logical layer."
  type        = map(string)
  default = {
    raw     = "ec_raw"
    staging = "ec_staging"
    core    = "ec_core"
    mart    = "ec_mart"
  }
}

# Hard cost guard: Athena cancels any single query scanning more than this.
variable "athena_bytes_scanned_cutoff" {
  description = "Per-query scan cutoff for the Athena workgroup (bytes)."
  type        = number
  default     = 2147483648 # 2 GiB
}

variable "tags" {
  description = "Common tags for cost tracking."
  type        = map(string)
  default = {
    project     = "ec-portfolio"
    managed_by  = "terraform"
    environment = "dev"
  }
}
