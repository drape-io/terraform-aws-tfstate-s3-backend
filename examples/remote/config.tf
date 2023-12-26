provider "aws" {
  access_key = "dev-tfstate-backend"
  secret_key = "dev-tfstate-backend"
  region     = "us-east-1"

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs#s3_use_path_style
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3       = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    sqs      = "http://localhost:4566"
    kms      = "http://localhost:4566"
  }
}

terraform {
  backend "s3" {
    bucket = "drape-customer1-dev-k8s-tfstate"
    key    = "app1"
    region = "us-east-1"
    endpoint= "http://localhost:4566"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true

    force_path_style            = true
    dynamodb_endpoint           = "http://localhost:4566"
  }
}
