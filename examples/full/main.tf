locals {
  context = {
    group  = "drape"
    tenant = "customer1"
    scope  = "k8s"
    env    = "dev"
    tags = {
      "Owner" : "group-sre@test.com"
    }
  }
}

module "full" {
  source        = "../../"
  context       = local.context
  force_destroy = true
}

module "full_replication" {
  source              = "../../modules/replication"
  context             = local.context
  force_destroy       = true
  primary_bucket_name = module.full.primary_s3_bucket
  primary_bucket_arn  = module.full.primary_s3_arn
  providers = {
    aws           = aws
    aws.secondary = aws.secondary
  }
}

module "prd" {
  source        = "../../"
  force_destroy = true
  context = merge(
    local.context,
    {
      env = "prd"
    }
  )
}
