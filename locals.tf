locals {
  enabled      = module.context.context.enabled
  context      = module.context.context
  state_suffix = "tfstate"

  backend_config = local.enabled ? join("\n", [
    "terraform {",
    "  backend \"s3\" {",
    "    bucket         = \"${module.primary_s3.bucket}\"",
    "    key            = \"terraform.tfstate\"",
    "    region         = \"${data.aws_region.current.name}\"",
    "    dynamodb_table = \"${one(aws_dynamodb_table.default[*]).name}\"",
    "    encrypt        = true",
    "  }",
    "}",
  ]) : ""
}
