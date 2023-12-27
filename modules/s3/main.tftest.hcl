provider "aws" {
  access_key = "dev-tfstate-backend"
  secret_key = "dev-tfstate-backend"
  region     = "us-east-1"

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs#s3_use_path_style
  # s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    # s3       = "http://localhost:4566"
    s3 = "http://s3.127-0-0-1.nip.io:4566"
    dynamodb = "http://localhost:4566"
    iam      = "http://localhost:4566"
  }
}

variables {
  context = {
    group = "drape"
    env   = "dev"
    scope = "s3-module"
  }
}

run "test_s3_single_region_plan" {
  command = plan

  assert {
    condition     = aws_s3_bucket.default[0].bucket == "drape-dev-s3-module-tfstate"
    error_message = "S3 bucket wasn't created with the correct context name"
  }
}

run "test_s3_enabled_works" {
  command = plan
  variables {
    context = {
      enabled = false
      group   = "drape"
      env     = "dev"
    }

  }

  assert {
    condition     = length(aws_s3_bucket.default) == 0
    error_message = "S3 bucket was created when we weren't enabled"
  }
}

