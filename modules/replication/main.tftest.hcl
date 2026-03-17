provider "aws" {
  access_key = "dev-tfstate-backend"
  secret_key = "dev-tfstate-backend"
  region     = "us-east-1"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3       = "http://s3.127-0-0-1.nip.io:4566"
    dynamodb = "http://localhost:4566"
    iam      = "http://localhost:4566"
  }
}

provider "aws" {
  alias      = "secondary"
  access_key = "dev-tfstate-backend"
  secret_key = "dev-tfstate-backend"
  region     = "us-west-2"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3       = "http://s3.127-0-0-1.nip.io:4566"
    dynamodb = "http://localhost:4566"
    iam      = "http://localhost:4566"
  }
}

variables {
  sse_algorithm       = "AES256"
  primary_bucket_name = "drape-dev-tfstate"
  primary_bucket_arn  = "arn:aws:s3:::drape-dev-tfstate"
  context = {
    group = "drape"
    env   = "dev"
  }
}

run "test_replication_plan" {
  command = plan

  assert {
    condition     = module.secondary_s3.bucket != ""
    error_message = "Secondary S3 bucket should be created"
  }

  assert {
    condition     = aws_iam_role.replication.name != ""
    error_message = "Replication IAM role should be created"
  }

  assert {
    condition     = aws_s3_bucket_replication_configuration.replication.bucket == "drape-dev-tfstate"
    error_message = "Replication should target the primary bucket"
  }
}

run "test_replication_apply" {
  variables {
    force_destroy       = true
    primary_bucket_name = "drape-dev-tfstate"
    primary_bucket_arn  = "arn:aws:s3:::drape-dev-tfstate"
    context = {
      group = "drape"
      env   = "dev"
    }
  }

  assert {
    condition     = output.secondary_s3_bucket != ""
    error_message = "Secondary bucket output should not be empty"
  }

  assert {
    condition     = output.secondary_s3_arn != ""
    error_message = "Secondary bucket ARN output should not be empty"
  }

  assert {
    condition     = output.replication_role_arn != ""
    error_message = "Replication role ARN output should not be empty"
  }
}
