output "data_bucket" {
  description = "S3 bucket for lakehouse data (raw/staging/core/mart prefixes)."
  value       = aws_s3_bucket.data.bucket
}

output "query_results_bucket" {
  description = "S3 bucket for Athena query results."
  value       = aws_s3_bucket.query_results.bucket
}

output "glue_databases" {
  description = "Glue catalog databases keyed by layer."
  value       = { for k, db in aws_glue_catalog_database.layers : k => db.name }
}

output "athena_workgroup" {
  description = "Athena workgroup name."
  value       = aws_athena_workgroup.ec.name
}

output "region" {
  value = var.region
}
