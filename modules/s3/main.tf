resource "aws_s3_bucket" "default" {
  count         = var.enabled ? 1 : 0
  bucket        = lower(substr(format("%s-%s", var.id, var.state_suffix), 0, 63))
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  count  = var.enabled ? 1 : 0
  bucket = aws_s3_bucket.default[0].id

  lifecycle {
    precondition {
      condition     = var.kms_key_id == null || startswith(var.sse_algorithm, "aws:kms")
      error_message = "kms_key_id can only be set when sse_algorithm is aws:kms or aws:kms:dsse."
    }
  }

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.kms_key_id
    }
  }
}

resource "aws_s3_bucket_versioning" "default" {
  count  = var.enabled ? 1 : 0
  bucket = aws_s3_bucket.default[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html
resource "aws_s3_bucket_public_access_block" "default" {
  count                   = var.enabled ? 1 : 0
  bucket                  = aws_s3_bucket.default[0].id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "tls_only" {
  count = var.enabled ? 1 : 0

  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.default[0].arn,
      "${aws_s3_bucket.default[0].arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "tls_only" {
  count  = var.enabled ? 1 : 0
  bucket = aws_s3_bucket.default[0].id
  policy = data.aws_iam_policy_document.tls_only[0].json

  # Changing the bucket policy and the public access block at the same time can
  # fail with OperationAborted.
  depends_on = [aws_s3_bucket_public_access_block.default]
}

resource "aws_s3_bucket_lifecycle_configuration" "default" {
  count      = var.enabled && var.enable_lifecycle_rules ? 1 : 0
  depends_on = [aws_s3_bucket_versioning.default]

  bucket = aws_s3_bucket.default[0].id

  rule {
    id = "Noncurrent expiration"

    filter {}

    # Transition old versions to Infrequent Access
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    # Transition old versions to Glacier
    noncurrent_version_transition {
      noncurrent_days = 60
      storage_class   = "GLACIER"
    }

    # Expire (delete) old versions.
    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    status = "Enabled"
  }

  rule {
    id = "Abort incomplete multipart uploads"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    status = "Enabled"
  }
}
