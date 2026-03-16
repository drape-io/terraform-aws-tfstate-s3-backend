module "replication-context" {
  count   = local.enabled && var.enable_replication ? 1 : 0
  source  = "drape-io/context/null"
  version = "~> 0.0.8"
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

data "aws_iam_policy_document" "replication_assume_role" {
  count = local.enabled && var.enable_replication ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["s3.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

resource "aws_iam_role" "replication" {
  count              = local.enabled && var.enable_replication ? 1 : 0
  name               = local.repl-ctx.id_truncated_hash
  assume_role_policy = data.aws_iam_policy_document.replication_assume_role[0].json
  tags               = local.repl-ctx.tags
}

data "aws_iam_policy_document" "replication" {
  count = local.enabled && var.enable_replication ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
    resources = [module.primary_s3.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
    ]
    resources = ["${module.primary_s3.arn}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
    ]
    resources = ["${module.secondary_s3[0].arn}/*"]
  }
}

resource "aws_iam_policy" "replication" {
  count  = local.enabled && var.enable_replication ? 1 : 0
  name   = local.repl-ctx.id_full
  policy = data.aws_iam_policy_document.replication[0].json
  tags   = local.repl-ctx.tags
}

resource "aws_iam_role_policy_attachment" "replication" {
  count      = local.enabled && var.enable_replication ? 1 : 0
  role       = aws_iam_role.replication[0].name
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
