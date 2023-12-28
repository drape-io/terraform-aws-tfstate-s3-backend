locals {
  context = {
    group   = "drape"
    tenant  = "customer1"
    scope   = "k8s"
    env     = "dev"
    tags = {
      "Owner" : "group-sre@test.com"
    }
  }
}

module "full" {
  source        = "../../"
  context       = local.context
  force_destroy = true
  enable_replication = true
  providers = {
    aws.secondary = aws.secondary
  }
}

module "secondary" {
  source        = "../../"
  force_destroy = true
  context = merge(
    local.context,
    {
      env = "prd"
    }
  )
  providers = {
    aws.secondary = aws.secondary
  }
}
