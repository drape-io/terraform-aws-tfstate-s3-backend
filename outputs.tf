output "primary_s3_bucket" {
  value = local.enabled ? module.primary_s3.bucket : ""
}

output "primary_s3_arn" {
  value = local.enabled ? module.primary_s3.arn : ""
}

output "dynamo_table" {
  value = local.enabled ? one(aws_dynamodb_table.default[*]).name : ""
}

output "enabled" {
  value       = local.enabled
  description = "If it was enabled or not"
}
