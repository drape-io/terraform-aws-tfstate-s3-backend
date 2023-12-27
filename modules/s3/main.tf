module "context" {
  source  = "drape-io/context/null"
  version = "0.0.7"
  # We override the max_id_length to guarantee to that we aren't larger than
  # available s3 bucket limits.
  context = merge(
    var.context, {
      max_id_length = 63
    }
  )
}

resource "aws_s3_bucket" "default" {
  count = local.enabled ? 1 : 0
  bucket = substr(format("%s-tfstate", module.context.id_truncated_hash), 0, 63)
  force_destroy = var.force_destroy
  tags = module.context.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  count = local.enabled ? 1 : 0
  bucket = aws_s3_bucket.default[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "default" {
  count = local.enabled ? 1 : 0
  bucket = aws_s3_bucket.default[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html
resource "aws_s3_bucket_public_access_block" "default" {
  count = local.enabled ? 1 : 0
  bucket                  = aws_s3_bucket.default[0].id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "default" {
  count    = local.enabled ? 1 : 0
  depends_on = [aws_s3_bucket_versioning.default]

  bucket = aws_s3_bucket.default[0].id

  rule {
    id = "Noncurrent expiration"

    # Transition old versions to Infrequent Access
    noncurrent_version_transition {
      noncurrent_days = 15
      storage_class   = "STANDARD_IA"
    }

    # Transition old versions to Glacier 
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }

    # Expire (delete) old versions.
    noncurrent_version_expiration {
      noncurrent_days = 45
    }


    status = "Enabled"
  }

  rule {
    id = "Abort incomplete multipart uploads"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    status = "Enabled"
  }
}
