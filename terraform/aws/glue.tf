# Glue Data Catalog databases = Athena schemas. One per logical layer, with the
# table data location under the corresponding S3 prefix.
resource "aws_glue_catalog_database" "layers" {
  for_each = var.glue_databases

  name        = each.value
  description = "EC portfolio ${each.key} layer"

  location_uri = "s3://${aws_s3_bucket.data.bucket}/${each.key}/"
}
