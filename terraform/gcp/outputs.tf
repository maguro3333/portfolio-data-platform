output "raw_bucket" {
  description = "GCS bucket for raw CSV landing."
  value       = google_storage_bucket.raw.name
}

output "bigquery_datasets" {
  description = "Created BigQuery dataset IDs keyed by layer."
  value       = { for k, ds in google_bigquery_dataset.layers : k => ds.dataset_id }
}

output "project_id" {
  description = "Active GCP project."
  value       = var.project_id
}

output "location" {
  description = "Data location."
  value       = var.location
}
