# One dataset per logical layer (raw / staging / core / mart). Names match the
# dbt bigquery target so the same models materialize here.
resource "google_bigquery_dataset" "layers" {
  for_each = var.bq_datasets

  dataset_id  = each.value
  project     = var.project_id
  location    = var.location
  description = "EC portfolio ${each.key} layer"

  # dev convenience: allow `terraform destroy` to drop datasets with tables.
  delete_contents_on_destroy = true

  labels = merge(var.labels, { environment = var.environment, layer = each.key })

  depends_on = [google_project_service.services]
}
