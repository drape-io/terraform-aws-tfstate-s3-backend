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

variables {
  id            = "drape-dev-s3-module"
  sse_algorithm = "AES256"
  tags = {
    "Owner" = "test@test.com"
  }
}

run "test_s3_single_region_plan" {
  command = plan

  assert {
    condition     = aws_s3_bucket.default[0].bucket == "drape-dev-s3-module-tfstate"
    error_message = "S3 bucket wasn't created with the correct context name"
  }

  assert {
    condition     = aws_s3_bucket.default[0].tags["Owner"] == "test@test.com"
    error_message = "S3 bucket tags were not propagated from context"
  }
}

run "test_s3_enabled_works" {
  command = plan
  variables {
    enabled = false
  }

  assert {
    condition     = length(aws_s3_bucket.default) == 0
    error_message = "S3 bucket was created when we weren't enabled"
  }
}

run "test_s3_apply" {
  assert {
    condition     = output.bucket == "drape-dev-s3-module-tfstate"
    error_message = "S3 bucket name wasn't in output"
  }

  assert {
    condition     = output.arn != ""
    error_message = "S3 bucket ARN should not be empty"
  }

  assert {
    condition     = strcontains(aws_s3_bucket_policy.tls_only[0].policy, "aws:SecureTransport")
    error_message = "S3 bucket should deny requests that don't use TLS"
  }
}

run "test_s3_encryption" {
  command = plan
  variables {
    sse_algorithm = "aws:kms"
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.default[0].rule).apply_server_side_encryption_by_default).sse_algorithm == "aws:kms"
    error_message = "S3 bucket should allow KMS encryption"
  }
}

run "test_s3_encryption_custom" {
  command = plan

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.default[0].rule).apply_server_side_encryption_by_default).sse_algorithm == "AES256"
    error_message = "S3 bucket should allow AES256 encryption override"
  }
}

run "test_s3_public_access_blocked" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.default[0].block_public_acls == true
    error_message = "S3 bucket should block public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.default[0].ignore_public_acls == true
    error_message = "S3 bucket should ignore public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.default[0].block_public_policy == true
    error_message = "S3 bucket should block public policy"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.default[0].restrict_public_buckets == true
    error_message = "S3 bucket should restrict public buckets"
  }
}

run "test_s3_versioning_enabled" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.default[0].versioning_configuration[0].status == "Enabled"
    error_message = "S3 bucket versioning should be enabled"
  }
}

run "test_s3_bucket_name_is_lowercase" {
  command = plan
  variables {
    id = "Drape-Dev"
  }

  assert {
    condition     = aws_s3_bucket.default[0].bucket == "drape-dev-tfstate"
    error_message = "S3 bucket name should be lowercase"
  }
}

run "test_s3_kms_key_requires_kms_algorithm" {
  command = plan
  variables {
    sse_algorithm = "AES256"
    kms_key_id    = "arn:aws:kms:us-east-1:111122223333:key/00000000-0000-0000-0000-000000000000"
  }

  expect_failures = [aws_s3_bucket_server_side_encryption_configuration.default]
}
