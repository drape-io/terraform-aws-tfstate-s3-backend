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
    condition     = aws_iam_role.replication[0].name == "drape-dev-s3-replication"
    error_message = "Replication IAM role should be created"
  }

  assert {
    condition     = aws_s3_bucket_replication_configuration.replication[0].bucket == "drape-dev-tfstate"
    error_message = "Replication should target the primary bucket"
  }
}

run "test_replication_disabled" {
  command = plan
  variables {
    context = {
      enabled = false
      group   = "drape"
      env     = "dev"
    }
  }

  assert {
    condition     = length(aws_iam_role.replication) == 0 && length(aws_s3_bucket_replication_configuration.replication) == 0
    error_message = "Replication resources were created when we weren't enabled"
  }
}

# Replication needs a real, versioned source bucket.
run "setup_primary_bucket" {
  module {
    source = "../s3"
  }

  variables {
    id            = "drape-dev"
    force_destroy = true
  }
}

run "test_replication_apply" {
  variables {
    force_destroy       = true
    primary_bucket_name = run.setup_primary_bucket.bucket
    primary_bucket_arn  = run.setup_primary_bucket.arn
  }

  assert {
    condition     = output.secondary_s3_bucket == "drape-dev-replica-tfstate"
    error_message = "Secondary bucket should be named after the replica context"
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

run "test_replication_context_rejects_invalid_characters" {
  command = plan
  variables {
    context = {
      group      = "drape"
      env        = "dev"
      attributes = ["not_valid"]
    }
  }

  expect_failures = [var.context]
}
