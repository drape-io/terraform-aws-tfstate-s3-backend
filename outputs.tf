output "primary_s3_bucket" {
  value = local.enabled ? one(aws_s3_bucket.default[*]).id : ""
}

output "dynamo_table" {
  value = local.enabled ? one(aws_dynamodb_table.default[*]).name : ""
}

output "enabled" {
  value       = local.enabled
  description = "If it was enabled or not"
}
