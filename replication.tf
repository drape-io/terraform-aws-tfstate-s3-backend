module "replication-context" {
  count   = local.enabled && var.enable_replication ? 1 : 0
  source  = "drape-io/context/null"
  version = "0.0.8"
  context = merge(
    local.context,
    {
      attributes = concat(local.context.attributes, ["s3-replication"]),
    }
  )
}

locals {
  repl-ctx = local.enabled && var.enable_replication ? module.replication-context[0] : null
}

resource "aws_iam_role" "replication" {
  count              = local.enabled && var.enable_replication ? 1 : 0
  name               = local.repl-ctx.id_truncated_hash
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "replication" {
  count  = local.enabled && var.enable_replication ? 1 : 0
  name   = local.repl-ctx.id_full
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${module.primary_s3.arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl"
      ],
      "Effect": "Allow",
      "Resource": [
        "${module.primary_s3.arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete"
      ],
      "Effect": "Allow",
      "Resource": "${module.secondary_s3[0].arn}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "replication" {
  count      = local.enabled && var.enable_replication ? 1 : 0
  name       = local.repl-ctx.id_full
  roles      = ["${aws_iam_role.replication[0].name}"]
  policy_arn = aws_iam_policy.replication[0].arn
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  count  = local.enabled && var.enable_replication ? 1 : 0
  role   = aws_iam_role.replication[0].arn
  bucket = module.primary_s3.bucket

  rule {
    id     = local.repl-ctx.id_full
    status = "Enabled"

    destination {
      bucket        = module.secondary_s3[0].arn
      storage_class = "STANDARD"
    }
  }
}
