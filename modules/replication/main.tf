data "aws_partition" "current" {}

module "context" {
  source  = "drape-io/context/null"
  version = "~> 0.0.8"
  context = merge(
    var.context, {
      max_id_length = 63
    }
  )
}

locals {
  context = module.context.context
  enabled = local.context.enabled
}

module "secondary_context" {
  source  = "drape-io/context/null"
  version = "~> 0.0.8"
  context = merge(
    local.context,
    {
      attributes    = concat(local.context.attributes, ["replica"]),
      max_id_length = 63
    }
  )
}

module "replication_context" {
  source  = "drape-io/context/null"
  version = "~> 0.0.8"
  context = merge(
    local.context,
    {
      attributes = concat(local.context.attributes, ["s3-replication"]),
    }
  )
  # IAM role names are limited to 64 characters.
  max_id_length = 64
}

module "secondary_s3" {
  source                 = "../s3"
  enabled                = local.enabled
  id                     = module.secondary_context.id_truncated_hash
  tags                   = module.secondary_context.tags
  state_suffix           = "tfstate"
  force_destroy          = var.force_destroy
  sse_algorithm          = var.sse_algorithm
  kms_key_id             = var.kms_key_id
  enable_lifecycle_rules = var.enable_lifecycle_rules

  providers = {
    aws = aws.secondary
  }
}

data "aws_iam_policy_document" "replication_assume_role" {
  count = local.enabled ? 1 : 0

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
  count              = local.enabled ? 1 : 0
  name               = module.replication_context.id_truncated_hash
  assume_role_policy = data.aws_iam_policy_document.replication_assume_role[0].json
  tags               = module.replication_context.tags
}

data "aws_iam_policy_document" "replication" {
  count = local.enabled ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
    resources = [var.primary_bucket_arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
    ]
    resources = ["${var.primary_bucket_arn}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
    ]
    resources = ["${module.secondary_s3.arn}/*"]
  }
}

resource "aws_iam_policy" "replication" {
  count  = local.enabled ? 1 : 0
  name   = module.replication_context.id_full
  policy = data.aws_iam_policy_document.replication[0].json
  tags   = module.replication_context.tags
}

resource "aws_iam_role_policy_attachment" "replication" {
  count      = local.enabled ? 1 : 0
  role       = aws_iam_role.replication[0].name
  policy_arn = aws_iam_policy.replication[0].arn
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  count  = local.enabled ? 1 : 0
  role   = aws_iam_role.replication[0].arn
  bucket = var.primary_bucket_name

  # The destination bucket must have versioning enabled before replication
  # can be configured, and the arn output doesn't wait for it.
  depends_on = [module.secondary_s3]

  rule {
    id     = module.replication_context.id_full
    status = "Enabled"

    destination {
      bucket        = module.secondary_s3.arn
      storage_class = "STANDARD"
    }
  }
}

moved {
  from = aws_iam_role.replication
  to   = aws_iam_role.replication[0]
}

moved {
  from = aws_iam_policy.replication
  to   = aws_iam_policy.replication[0]
}

moved {
  from = aws_iam_role_policy_attachment.replication
  to   = aws_iam_role_policy_attachment.replication[0]
}

moved {
  from = aws_s3_bucket_replication_configuration.replication
  to   = aws_s3_bucket_replication_configuration.replication[0]
}
