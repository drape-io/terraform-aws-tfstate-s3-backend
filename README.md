# drape-io/tfstate-s3-backend/aws
## Overview
Terraform module for provisioning an S3 bucket for the terraform remote state
backend with proper security and locking configured.

Uses [drape-io/context/null](https://github.com/drape-io/terraform-null-context)
for consistent tagging and naming of resources.

You can use it like this:

```hcl
module "tfstate-backend" {
  source  = "github.com/drape-io/terraform-aws-tfstate-s3-backend"
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
  source  = "github.com/drape-io/terraform-aws-tfstate-s3-backend"
  context = merge(local.context, {
    attributes = ["primary"]
  })
  providers = {
    aws.secondary = aws
  }
}
module "secondary-tfstate-backend" {
  source  = "github.com/drape-io/terraform-aws-tfstate-s3-backend"
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
  source  = "github.com/drape-io/terraform-aws-tfstate-s3-backend"
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
  source  = "github.com/drape-io/terraform-aws-tfstate-s3-backend"
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
  source  = "github.com/drape-io/terraform-aws-tfstate-s3-backend"
  context = local.context
  enable_replication = true
  providers = {
    aws.secondary = aws.secondary
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_context"></a> [context](#module\_context) | drape-io/context/null | ~> 0.0.8 |
| <a name="module_primary_s3"></a> [primary\_s3](#module\_primary\_s3) | ./modules/s3 | n/a |
| <a name="module_replication-context"></a> [replication-context](#module\_replication-context) | drape-io/context/null | ~> 0.0.8 |
| <a name="module_secondary_context"></a> [secondary\_context](#module\_secondary\_context) | drape-io/context/null | ~> 0.0.8 |
| <a name="module_secondary_s3"></a> [secondary\_s3](#module\_secondary\_s3) | ./modules/s3 | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_iam_policy.replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket_replication_configuration.replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration) | resource |
| [aws_iam_policy_document.replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.replication_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Used to pass an object of any of the variables used to this module.  It is<br>used to seed the module with labels from another context. | <pre>object({<br>    enabled    = optional(bool)<br>    group      = optional(string)<br>    tenant     = optional(string)<br>    env        = optional(string)<br>    scope      = optional(string)<br>    attributes = optional(list(string))<br>    tags       = optional(map(string))<br>  })</pre> | n/a | yes |
| <a name="input_enable_lifecycle_rules"></a> [enable\_lifecycle\_rules](#input\_enable\_lifecycle\_rules) | Whether to enable the default S3 lifecycle rules for noncurrent version tiering and cleanup | `bool` | `true` | no |
| <a name="input_enable_replication"></a> [enable\_replication](#input\_enable\_replication) | This enables replication to a secondary region | `bool` | `false` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Allow the S3 bucket to be destroyed. By default we do not want to allow this | `bool` | `false` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS key ARN for S3 encryption. If null, the default aws/s3 KMS key is used when sse\_algorithm is aws:kms | `string` | `null` | no |
| <a name="input_sse_algorithm"></a> [sse\_algorithm](#input\_sse\_algorithm) | Server-side encryption algorithm for S3. Use 'aws:kms' for KMS or 'AES256' for S3-managed keys | `string` | `"aws:kms"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backend_config"></a> [backend\_config](#output\_backend\_config) | A generated Terraform backend configuration block that can be copy/pasted into your root module |
| <a name="output_dynamo_table"></a> [dynamo\_table](#output\_dynamo\_table) | The name of the DynamoDB table used for state locking |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether the module is enabled |
| <a name="output_primary_s3_arn"></a> [primary\_s3\_arn](#output\_primary\_s3\_arn) | The ARN of the primary S3 bucket |
| <a name="output_primary_s3_bucket"></a> [primary\_s3\_bucket](#output\_primary\_s3\_bucket) | The name of the primary S3 bucket for storing Terraform state |
| <a name="output_secondary_s3_arn"></a> [secondary\_s3\_arn](#output\_secondary\_s3\_arn) | The ARN of the secondary (replica) S3 bucket, empty if replication is disabled |
| <a name="output_secondary_s3_bucket"></a> [secondary\_s3\_bucket](#output\_secondary\_s3\_bucket) | The name of the secondary (replica) S3 bucket, empty if replication is disabled |
<!-- END_TF_DOCS -->
