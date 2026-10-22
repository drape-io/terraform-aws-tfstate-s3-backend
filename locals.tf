locals {
  enabled      = module.context.context.enabled
  state_suffix = "tfstate"

  backend_config = local.enabled ? join("\n", [
    "terraform {",
    "  backend \"s3\" {",
    "    bucket         = \"${module.primary_s3.bucket}\"",
    "    key            = \"terraform.tfstate\"",
    "    region         = \"${module.primary_s3.region}\"",
    "    dynamodb_table = \"${one(aws_dynamodb_table.default[*]).name}\"",
    "    encrypt        = true",
    "  }",
    "}",
  ]) : ""
}
