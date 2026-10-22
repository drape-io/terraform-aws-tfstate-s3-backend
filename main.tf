module "context" {
  source  = "drape-io/context/null"
  version = "~> 0.0.8"
  context = var.context
  # S3 bucket names are limited to 63 characters. Leave room for the
  # "-tfstate" suffix so a long id is shortened with a hash, not cut off.
  max_id_length = 55
}

module "primary_s3" {
  source                 = "./modules/s3"
  enabled                = local.enabled
  id                     = local.id
  tags                   = module.context.tags
  state_suffix           = local.state_suffix
  force_destroy          = var.force_destroy
  sse_algorithm          = var.sse_algorithm
  kms_key_id             = var.kms_key_id
  enable_lifecycle_rules = var.enable_lifecycle_rules
}
