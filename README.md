# drape-io/tfstate-s3-backend/aws
## Overview
Terraform module for provisioning an S3 bucket for the terraform remote state
backend with proper security and locking configured.

Uses [drape-io/context/null](https://github.com/drape-io/terraform-null-context)
for consistent tagging and naming of resources.

You can use it like this:

```hcl
module "tfstate-backend" {
  source  = "drape-io/tfstate-s3-backend/aws"
  context = {
    group = "drape"
    env    = "dev"
    tags = {
      "Owner" : "group-sre@test.com"
    }
  }
  providers = {
    aws.secondary = aws
  }
}
```

*NOTE*: The `providers` block is required.  This is because if in the future you
would like to use replication to another region we need you to pass in the
provider.

It will generate an s3 bucket `drape-dev-tfstate`. We use the [context](https://github.com/drape-io/terraform-null-context)
to manage the tagging and naming of resources.   If you need to generate a more
unique name for the bucket you can use a combination of the fields in the
context. For example, to create two state buckets in the same environment:

```hcl
locals {
  context = {
    group = "drape"
    env    = "dev"
    tags = {
      "Owner" : "group-sre@test.com"
    }
  }
}
module "primary-tfstate-backend" {
  source  = "drape-io/tfstate-s3-backend/aws"
  context = merge(local.context, {
    attributes = ["primary"]
  })
  providers = {
    aws.secondary = aws
  }
}
module "secondary-tfstate-backend" {
  source  = "drape-io/tfstate-s3-backend/aws"
  context = merge(local.context, {
    attributes = ["secondary"]
  })
  providers = {
    aws.secondary = aws
  }
}
```

Which will create two buckets:

- drape-dev-primary-tfstate
- drape-dev-secondary-tfstate

## Encryption

By default, S3 buckets are encrypted with AWS KMS (`aws:kms`). You can
customize the encryption:

```hcl
module "tfstate-backend" {
  source  = "drape-io/tfstate-s3-backend/aws"
  context = local.context

  # Use a custom KMS key
  kms_key_id = aws_kms_key.my_key.arn

  # Or use S3-managed keys instead of KMS
  # sse_algorithm = "AES256"

  providers = {
    aws.secondary = aws
  }
}
```

## Deletion Protection

The DynamoDB lock table has deletion protection enabled by default. This
prevents accidental deletion of the lock table which would break all terraform
runs using this backend.

When `force_destroy = true` is set, deletion protection is disabled to allow
teardown of the entire backend.

# Destroying
If you try to teardown a module that uses this you will get the error:

```
│ Error: deleting Amazon S3 (Simple Storage) Bucket (drape-customer1-dev-k8s-tfstate): BucketNotEmpty: The bucket you tried to delete is not empty. You must delete all versions in the bucket.
│ 	status code: 409, request id: ec63f05f-f745-4c17-8159-0bc9fc0e1d08, host id: s9lzHYrFp76ZVxRcpX9+5cjAnEH2ROuNkd2BHfIa6UkFVdtjf5mKR3/eTPFvsiP/XV/VLi31234=
```

This is because we protect you from deleting state on accident.  To fix this you
need to set the variable `force_destroy = true`, then apply before running
destroy:

```hcl
module "primary-tfstate-backend" {
  source  = "drape-io/tfstate-s3-backend/aws"
  force_destroy = true
  context = local.context
  providers = {
    aws.secondary = aws
  }
}
```

```bash
terraform apply
terraform destroy
```

# Replication
We support cross-region replication for additional disaster recovery by doing
the following:

1. Define your secondary provider:

```hcl
provider "aws" {
  alias   = "secondary"
  region  = "us-west-2"
}
```

2. Then pass it in to the module:
```hcl
module "primary-tfstate-backend" {
  source  = "drape-io/tfstate-s3-backend/aws"
  context = local.context
  enable_replication = true
  providers = {
    aws.secondary = aws.secondary
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| context | Used to pass an object of any of the variables used to this module. It is used to seed the module with labels from another context. | `object({...})` | n/a | yes |
| enable_replication | This enables replication to a secondary region | `bool` | `false` | no |
| force_destroy | Allow the S3 bucket to be destroyed. By default we do not want to allow this | `bool` | `false` | no |
| sse_algorithm | Server-side encryption algorithm for S3. Use `aws:kms` for KMS or `AES256` for S3-managed keys | `string` | `"aws:kms"` | no |
| kms_key_id | KMS key ARN for S3 encryption. If null, the default aws/s3 KMS key is used when sse_algorithm is aws:kms | `string` | `null` | no |
| enable_lifecycle_rules | Whether to enable the default S3 lifecycle rules for noncurrent version tiering and cleanup | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| primary_s3_bucket | The name of the primary S3 bucket for storing Terraform state |
| primary_s3_arn | The ARN of the primary S3 bucket |
| secondary_s3_bucket | The name of the secondary (replica) S3 bucket, empty if replication is disabled |
| secondary_s3_arn | The ARN of the secondary (replica) S3 bucket, empty if replication is disabled |
| dynamo_table | The name of the DynamoDB table used for state locking |
| enabled | Whether the module is enabled |
