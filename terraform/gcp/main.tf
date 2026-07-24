# Enable the APIs this foundation needs. The project already exists; these are
# idempotent. Not disabled on destroy so tearing down data resources does not
# turn off services that may be shared.
resource "google_project_service" "services" {
  for_each = toset([
    "storage.googleapis.com",
    "bigquery.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}
