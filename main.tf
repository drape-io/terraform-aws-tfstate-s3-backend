data "aws_partition" "current" {}

module "context" {
  source  = "drape-io/context/null"
  version = "0.0.5"
  context = var.context
}