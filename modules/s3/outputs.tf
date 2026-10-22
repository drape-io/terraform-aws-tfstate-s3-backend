output "bucket" {
  description = "The name of the S3 bucket (depends on versioning to ensure replication readiness)"
  # We depend on the versioning rather than the bucket itself here because
  # if we enable replication it needs versioning enabled first.
  value = var.enabled ? one(aws_s3_bucket_versioning.default[*]).id : ""
}

output "arn" {
  description = "The ARN of the S3 bucket"
  value       = var.enabled ? one(aws_s3_bucket.default[*]).arn : ""
}

output "region" {
  description = "The region the S3 bucket lives in"
  value       = var.enabled ? one(aws_s3_bucket.default[*]).region : ""
}
