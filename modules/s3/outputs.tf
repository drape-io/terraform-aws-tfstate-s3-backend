output "bucket" {
  # We depend on the versioning rather than the bucket itself here because
  # if we enable replication it needs versioning enabled first.
  value = local.enabled ? one(aws_s3_bucket_versioning.default[*]).id : ""
}

output "arn" {
  value = local.enabled ? one(aws_s3_bucket.default[*]).arn : ""
}