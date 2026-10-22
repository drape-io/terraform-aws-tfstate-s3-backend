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
  sse_algorithm = "AES256"
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

  assert {
    condition     = aws_dynamodb_table.default[0].server_side_encryption[0].enabled == true
    error_message = "DynamoDB table should have server-side encryption enabled"
  }

  assert {
    condition     = aws_dynamodb_table.default[0].deletion_protection_enabled == true
    error_message = "DynamoDB table should have deletion protection enabled by default"
  }
}

run "test_dynamo_deletion_protection_disabled_with_force_destroy" {
  command = plan
  variables {
    force_destroy = true
  }

  assert {
    condition     = aws_dynamodb_table.default[0].deletion_protection_enabled == false
    error_message = "DynamoDB deletion protection should be disabled when force_destroy is true"
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
    force_destroy = true
  }

  assert {
    condition     = output.primary_s3_bucket == "drape-dev-tfstate"
    error_message = "S3 bucket name wasn't in output"
  }

  assert {
    condition     = output.dynamo_table == "drape-dev-tfstate"
    error_message = "dynamo table name wasn't in output"
  }

  assert {
    condition     = output.enabled == true
    error_message = "enabled output should be true"
  }

  assert {
    condition     = output.backend_config != ""
    error_message = "backend_config output should not be empty"
  }

  assert {
    condition     = strcontains(output.backend_config, "drape-dev-tfstate")
    error_message = "backend_config should contain the bucket name"
  }

  assert {
    condition     = strcontains(output.backend_config, "region         = \"us-east-1\"")
    error_message = "backend_config should contain the bucket's region"
  }
}

# Short ids must keep the names that existing state buckets and tables use.
run "test_sbx_table_name_unchanged" {
  command = plan
  variables {
    context = {
      group = "sontek"
      env   = "sbx"
    }
  }

  assert {
    condition     = aws_dynamodb_table.default[0].name == "sontek-sbx-tfstate"
    error_message = "Short id table name changed"
  }
}

run "test_short_id_names_unchanged" {
  variables {
    force_destroy = true
    context = {
      group      = "drp"
      env        = "mgmt"
      attributes = ["bootstrap"]
    }
  }

  assert {
    condition     = output.primary_s3_bucket == "drp-mgmt-bootstrap-tfstate"
    error_message = "Short id bucket name changed"
  }

  assert {
    condition     = output.dynamo_table == "drp-mgmt-bootstrap-tfstate"
    error_message = "Short id table name changed"
  }
}

run "test_long_id_is_shortened_with_hash" {
  variables {
    force_destroy = true
    context = {
      group  = "averyveryverylonggroupname"
      tenant = "anotherlongtenantname"
      env    = "production"
      scope  = "kubernetes-cluster"
    }
  }

  assert {
    condition     = length(output.primary_s3_bucket) <= 63 && endswith(output.primary_s3_bucket, "-tfstate")
    error_message = "Long id bucket name must fit in 63 characters and keep the -tfstate suffix"
  }

  assert {
    condition     = output.primary_s3_bucket == lower(output.primary_s3_bucket)
    error_message = "Bucket name must be lowercase"
  }

  assert {
    condition     = output.dynamo_table == output.primary_s3_bucket
    error_message = "Table and bucket names should match"
  }
}

run "test_context_rejects_invalid_characters" {
  command = plan
  variables {
    context = {
      group = "Drape"
      env   = "dev"
    }
  }

  expect_failures = [var.context]
}
