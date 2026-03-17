output "secondary_s3_bucket" {
  description = "The name of the secondary (replica) S3 bucket"
  value       = module.secondary_s3.bucket
}

output "secondary_s3_arn" {
  description = "The ARN of the secondary (replica) S3 bucket"
  value       = module.secondary_s3.arn
}

output "replication_role_arn" {
  description = "The ARN of the IAM role used for S3 replication"
  value       = aws_iam_role.replication.arn
}
