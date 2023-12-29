data "aws_partition" "current" {}

module "context" {
  source  = "drape-io/context/null"
  version = "0.0.8"
  # We override the max_id_length to guarantee to that we aren't larger than
  # available s3 bucket limits.
  context = merge(
    var.context, {
      max_id_length = 63
    }
  )
}

module "primary_s3" {
    source = "./modules/s3"
    context = module.context.context
}

module "secondary_s3" {
    count = var.enable_replication ? 1 : 0
    source = "./modules/s3"
    context = merge(
        local.context,
        {
            attributes = concat(local.context.attributes, ["2"])
        }
    )

    providers = {
        aws = aws.secondary
    }
}