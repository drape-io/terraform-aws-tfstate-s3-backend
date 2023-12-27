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
    # s3 = "http://localhost:4566"
    s3 = "http://s3.127-0-0-1.nip.io:4566"

    dynamodb = "http://localhost:4566"
    iam      = "http://localhost:4566"
  }
}

variables {
  context = {
    group = "drape"
    env   = "dev"
  }
}


run "test_dynamo_single_region_plan" {
  command = plan

  assert {
    condition     = aws_dynamodb_table.default[0].name == "drape-dev-tfstate"
    error_message = "Dynamo Table wasn't created with the correct context name"
  }
}

run "test_dynamo_enabled_works" {
  command = plan
  variables {
    context = {
      enabled = false
      group   = "drape"
      env     = "dev"
    }

  }

  assert {
    condition     = length(aws_dynamodb_table.default) == 0
    error_message = "Dynamo Table was created when we weren't enabled"
  }
}

run "test_apply_finishes" {
  variables {
    context = {
      group = "drape"
      env   = "dev"
    }

  }

  assert {
    condition     = output.primary_s3_bucket == "drape-dev-tfstate"
    error_message = "S3 bucket name wasn't in output"
  }

  assert {
    condition     = output.dynamo_table == "drape-dev-tfstate"
    error_message = "dynamo table name wasn't in output"
  }
}

run "test_apply_with_replication" {
  variables {
    enable_replication = true
    context = {
      group = "drape"
      env   = "dev"
    }

  }

  assert {
    condition     = output.primary_s3_bucket == "drape-dev-tfstate"
    error_message = "S3 bucket name wasn't in output"
  }

  assert {
    condition     = output.dynamo_table == "drape-dev-tfstate"
    error_message = "dynamo table name wasn't in output"
  }
}
