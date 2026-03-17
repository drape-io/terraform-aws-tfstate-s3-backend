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
  enabled = module.context.context.enabled
  context = module.context.context
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
  name               = module.replication_context.id_truncated_hash
  assume_role_policy = data.aws_iam_policy_document.replication_assume_role.json
  tags               = module.replication_context.tags
}

data "aws_iam_policy_document" "replication" {
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
  name   = module.replication_context.id_full
  policy = data.aws_iam_policy_document.replication.json
  tags   = module.replication_context.tags
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  role   = aws_iam_role.replication.arn
  bucket = var.primary_bucket_name

  rule {
    id     = module.replication_context.id_full
    status = "Enabled"

    destination {
      bucket        = module.secondary_s3.arn
      storage_class = "STANDARD"
    }
  }
}
