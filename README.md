# drape-io/tfstate-s3-backend/aws
## Overview
This Terraform module creates the S3 bucket and DynamoDB lock table for a
Terraform S3 remote state backend. The bucket blocks public access, uses
versioning and server-side encryption, and the lock table uses encryption.

The module uses [drape-io/context/null](https://github.com/drape-io/terraform-null-context)
to name and tag its resources.

Example:

```hcl
module "tfstate-backend" {
  source = "github.com/drape-io/terraform-aws-tfstate-s3-backend"
  context = {
    group = "drape"
    env   = "dev"
    tags = {
      "Owner" : "group-sre@test.com"
    }
  }
}
```

This example creates the bucket `drape-dev-tfstate`. To make the bucket name
unique, combine more fields of the context. For example, this creates two
state buckets in the same environment:

```hcl
locals {
  context = {
    group = "drape"
    env   = "dev"
    tags = {
      "Owner" : "group-sre@test.com"
    }
  }
}
module "primary-tfstate-backend" {
  source = "github.com/drape-io/terraform-aws-tfstate-s3-backend"
  context = merge(local.context, {
    attributes = ["primary"]
  })
}
module "secondary-tfstate-backend" {
  source = "github.com/drape-io/terraform-aws-tfstate-s3-backend"
  context = merge(local.context, {
    attributes = ["secondary"]
  })
}
```

The result is two buckets:

- drape-dev-primary-tfstate
- drape-dev-secondary-tfstate

## Encryption

The S3 bucket uses AWS KMS (`aws:kms`) default encryption. To change the
encryption, set `kms_key_id` or `sse_algorithm`:

```hcl
module "tfstate-backend" {
  source  = "github.com/drape-io/terraform-aws-tfstate-s3-backend"
  context = local.context

  # Use a custom KMS key
  kms_key_id = aws_kms_key.my_key.arn

  # Or use S3-managed keys instead of KMS
  # sse_algorithm = "AES256"
}
```

## Deletion Protection

The DynamoDB lock table has deletion protection on by default. If someone
deletes the lock table, every Terraform run that uses this backend fails.

If you set `force_destroy = true`, the module turns off deletion protection so
that you can destroy the full backend.

# Destroying
If you destroy a module that uses this backend, you get this error:

```
│ Error: deleting Amazon S3 (Simple Storage) Bucket (drape-customer1-dev-k8s-tfstate): BucketNotEmpty: The bucket you tried to delete is not empty. You must delete all versions in the bucket.
│ 	status code: 409, request id: ec63f05f-f745-4c17-8159-0bc9fc0e1d08, host id: s9lzHYrFp76ZVxRcpX9+5cjAnEH2ROuNkd2BHfIa6UkFVdtjf5mKR3/eTPFvsiP/XV/VLi31234=
```

The module prevents accidental deletion of state. To destroy the backend:

1. Set `force_destroy = true`:

```hcl
module "primary-tfstate-backend" {
  source        = "github.com/drape-io/terraform-aws-tfstate-s3-backend"
  force_destroy = true
  context       = local.context
}
```

2. Apply, then destroy:

```bash
terraform apply
terraform destroy
```

# Replication
The `modules/replication` submodule replicates the state bucket to a second
region for disaster recovery. The root module does not need a second provider.
You configure one only if you use replication.

1. Define the secondary provider:

```hcl
provider "aws" {
  alias  = "secondary"
  region = "us-west-2"
}
```

2. Create the primary backend:
```hcl
module "tfstate-backend" {
  source  = "github.com/drape-io/terraform-aws-tfstate-s3-backend"
  context = local.context
}
```

3. Call the replication submodule:
```hcl
module "tfstate-replication" {
  source              = "github.com/drape-io/terraform-aws-tfstate-s3-backend//modules/replication"
  context             = local.context
  primary_bucket_name = module.tfstate-backend.primary_s3_bucket
  primary_bucket_arn  = module.tfstate-backend.primary_s3_arn
  providers = {
    aws           = aws
    aws.secondary = aws.secondary
  }
}
```

The submodule creates the replica bucket `<id>-replica-tfstate` (for example,
`drape-dev-replica-tfstate`) in the secondary region. The replica gets the
same versioning, public access block and lifecycle rules as the primary
bucket. Its encryption comes from the submodule's `sse_algorithm` and
`kms_key_id` inputs.

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

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Used to pass an object of any of the variables used to this module.  It is<br>used to seed the module with labels from another context. | <pre>object({<br>    enabled    = optional(bool)<br>    group      = optional(string)<br>    tenant     = optional(string)<br>    env        = optional(string)<br>    scope      = optional(string)<br>    attributes = optional(list(string))<br>    tags       = optional(map(string))<br>  })</pre> | n/a | yes |
| <a name="input_enable_lifecycle_rules"></a> [enable\_lifecycle\_rules](#input\_enable\_lifecycle\_rules) | Whether to enable the default S3 lifecycle rules for noncurrent version tiering and cleanup | `bool` | `true` | no |
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
<!-- END_TF_DOCS -->
