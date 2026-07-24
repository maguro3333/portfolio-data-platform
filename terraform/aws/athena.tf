# Athena workgroup with enforced config: fixed result location, encryption, and
# a per-query scan cutoff as a hard cost guard (queries above the cutoff fail).
resource "aws_athena_workgroup" "ec" {
  name = "ec_portfolio"

  configuration {
    # Not enforced, so dbt-athena writes table data to its own s3_data_dir
    # (the persistent data bucket) rather than the enforced results location.
    # The per-query scan cutoff below still guards cost.
    enforce_workgroup_configuration    = false
    publish_cloudwatch_metrics_enabled = true
    bytes_scanned_cutoff_per_query     = var.athena_bytes_scanned_cutoff

    result_configuration {
      output_location = "s3://${aws_s3_bucket.query_results.bucket}/output/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  force_destroy = true
}
