data "aws_region" "current" {}

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
