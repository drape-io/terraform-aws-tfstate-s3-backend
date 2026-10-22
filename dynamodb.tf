resource "aws_dynamodb_table" "default" {
  count = local.enabled ? 1 : 0
  name  = format("%s-%s", module.context.id_truncated_hash, local.state_suffix)

  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = !var.force_destroy

  # https://developer.hashicorp.com/terraform/language/backend/s3#dynamodb_table
  hash_key = "LockID"

  server_side_encryption {
    enabled = true
  }

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = module.context.tags
}
