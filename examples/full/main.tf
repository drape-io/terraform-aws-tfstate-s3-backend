locals {
  context = {
    group         = "drape"
    tenant        = "customer1"
    scope         = "k8s"
    env           = "dev"
    max_id_length = 63
    tags = {
      "Owner" : "group-sre@test.com"
    }
  }
}

module "full" {
  source  = "../../"
  context = local.context
}

module "secondary" {
  source = "../../"
  context = merge(
    local.context,
    {
      env = "prd"
    }
  )
}
