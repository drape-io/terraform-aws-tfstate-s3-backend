data "aws_partition" "current" {}

module "context" {
  source  = "drape-io/context/null"
  version = "~> 0.0.8"
  # We override the max_id_length to guarantee to that we aren't larger than
  # available s3 bucket limits.
  context = merge(
    var.context, {
      max_id_length = 63
    }
  )
}

module "secondary_context" {
  count   = local.enabled && var.enable_replication ? 1 : 0
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

module "primary_s3" {
  source                 = "./modules/s3"
  enabled                = local.enabled
  id                     = module.context.id_truncated_hash
  tags                   = module.context.tags
  state_suffix           = local.state_suffix
  force_destroy          = var.force_destroy
  sse_algorithm          = var.sse_algorithm
  kms_key_id             = var.kms_key_id
  enable_lifecycle_rules = var.enable_lifecycle_rules
}

module "secondary_s3" {
  count                  = local.enabled && var.enable_replication ? 1 : 0
  source                 = "./modules/s3"
  enabled                = local.enabled
  id                     = module.secondary_context[0].id_truncated_hash
  tags                   = module.secondary_context[0].tags
  state_suffix           = local.state_suffix
  force_destroy          = var.force_destroy
  sse_algorithm          = var.sse_algorithm
  kms_key_id             = var.kms_key_id
  enable_lifecycle_rules = var.enable_lifecycle_rules

  providers = {
    aws = aws.secondary
  }
}
