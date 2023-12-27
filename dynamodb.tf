resource "aws_dynamodb_table" "default" {
  count = local.enabled ? 1 : 0
  name  = format("%s-tfstate", module.context.id_full)

  billing_mode = "PAY_PER_REQUEST"

  # https://www.terraform.io/docs/backends/types/s3.html#dynamodb_table
  hash_key = "LockID"

  server_side_encryption {
    enabled = true
  }

  # We don't need point in time recovery.  This table is only for locking
  /*
  point_in_time_recovery {
    enabled = true
  }
  */

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = module.context.tags
}
