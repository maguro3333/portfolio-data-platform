locals {
  account_id   = data.aws_caller_identity.current.account_id
  data_bucket  = "${var.project_prefix}-${local.account_id}-data"
  query_bucket = "${var.project_prefix}-${local.account_id}-athena-results"
}

# Lakehouse data bucket. Prefixes: raw/ (CSV.gz landing), staging/ core/ mart/
# (Parquet + selected Iceberg). Kept private; single bucket + clear prefixes.
resource "aws_s3_bucket" "data" {
  bucket        = local.data_bucket
  force_destroy = true # dev convenience for terraform destroy
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket                  = aws_s3_bucket.data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Athena query results, separated from table data. Short lifecycle keeps this
# from accumulating cost.
resource "aws_s3_bucket" "query_results" {
  bucket        = local.query_bucket
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "query_results" {
  bucket                  = aws_s3_bucket.query_results.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "query_results" {
  bucket = aws_s3_bucket.query_results.id
  rule {
    id     = "expire-query-results"
    status = "Enabled"
    filter {}
    expiration {
      days = 14
    }
  }
}
