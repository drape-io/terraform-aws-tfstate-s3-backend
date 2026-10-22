locals {
  enabled = module.context.context.enabled
  # The hash in a shortened id can contain uppercase letters, which S3 bucket
  # names don't allow.
  id           = lower(module.context.id_truncated_hash)
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
