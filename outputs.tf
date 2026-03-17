output "primary_s3_bucket" {
  description = "The name of the primary S3 bucket for storing Terraform state"
  value       = local.enabled ? module.primary_s3.bucket : ""
}

output "primary_s3_arn" {
  description = "The ARN of the primary S3 bucket"
  value       = local.enabled ? module.primary_s3.arn : ""
}

output "dynamo_table" {
  description = "The name of the DynamoDB table used for state locking"
  value       = local.enabled ? one(aws_dynamodb_table.default[*]).name : ""
}

output "enabled" {
  description = "Whether the module is enabled"
  value       = local.enabled
}

output "backend_config" {
  description = "A generated Terraform backend configuration block that can be copy/pasted into your root module"
  value       = local.backend_config
}
