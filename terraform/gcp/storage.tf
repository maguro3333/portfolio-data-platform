# Raw zone: landing area for the generated CSV.gz files before load into
# BigQuery. Kept private and single-region to match the datasets.
resource "google_storage_bucket" "raw" {
  name     = "${var.project_id}-ec-raw"
  location = var.location
  project  = var.project_id

  # Safety + hygiene
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  # dev convenience: allow `terraform destroy` to remove the bucket with objects
  force_destroy = true

  # Drop objects that are clearly stale to keep storage near-zero.
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  labels = merge(var.labels, { environment = var.environment, zone = "raw" })

  depends_on = [google_project_service.services]
}
