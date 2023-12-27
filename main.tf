data "aws_partition" "current" {}

module "context" {
  source  = "drape-io/context/null"
  version = "0.0.7"
  # We override the max_id_length to guarantee to that we aren't larger than
  # available s3 bucket limits.
  context = merge(
    var.context, {
      max_id_length = 63
    }
  )
}
