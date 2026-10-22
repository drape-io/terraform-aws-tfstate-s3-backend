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

# Naming

The bucket and the lock table are named `<id>-tfstate`, where `<id>` joins the
context fields. The `group`, `tenant`, `env`, `scope` and `attributes` fields
can contain only lowercase letters, numbers and hyphens.

S3 bucket names have a limit of 63 characters. If the id is longer than 55
characters, the module shortens it and adds a hash of the full id, so the name
fits and stays unique.

# Upgrading from 0.0.x

Version 1.0.0 changes some resources. Read this section before you apply it
to an existing backend.

## Changes to existing resources

- The default `sse_algorithm` changes from `AES256` to `aws:kms`, with the
  AWS managed `aws/s3` key. Terraform updates the bucket in place. New objects
  use KMS. Principals in other accounts cannot decrypt objects that use the
  AWS managed key. To keep the old behavior, set `sse_algorithm = "AES256"`.
- The DynamoDB lock table gets deletion protection, unless
  `force_destroy = true`.
- Each bucket gets a bucket policy that denies requests not made over TLS.
  A bucket has only one policy, so this replaces any policy that the bucket
  has now.
- The lifecycle rules get an empty `filter`. This is an in-place update.
- The `environment` tag of an `env` code expands to its full name. For
  example, `sbx` becomes `sandbox`. Tags generated from the context now
  override tags with the same key in `context.tags`. Terraform updates the
  tags in place.
- Names of ids up to 55 characters do not change. Longer ids get new bucket
  and table names, so Terraform replaces those resources.
- The `random_string` resources of the context module leave the state. No
  cloud resource changes.
- The module needs Terraform 1.6 or later and AWS provider 5.0 or later.

## Replication

Replication moved from the `enable_replication` variable to the
`modules/replication` submodule. Call the submodule as shown in
[Replication](#replication). Then add these blocks to the root module that
calls both modules. The `removed` blocks need Terraform 1.7 or later.

```hcl
moved {
  from = module.tfstate-backend.aws_iam_role.replication[0]
  to   = module.tfstate-replication.aws_iam_role.replication
}

moved {
  from = module.tfstate-backend.aws_iam_policy.replication[0]
  to   = module.tfstate-replication.aws_iam_policy.replication
}

moved {
  from = module.tfstate-backend.aws_s3_bucket_replication_configuration.replication[0]
  to   = module.tfstate-replication.aws_s3_bucket_replication_configuration.replication
}

# The policy attachment changes resource type. Keep the old attachment in AWS.
# If Terraform destroys it, it can detach the policy that the new attachment
# just attached.
removed {
  from = module.tfstate-backend.aws_iam_policy_attachment.replication
  lifecycle {
    destroy = false
  }
}

# The replica bucket name changes from <id>-2-tfstate to
# <id>-replica-tfstate. Keep the old replica bucket in AWS.
removed {
  from = module.tfstate-backend.module.secondary_s3
  lifecycle {
    destroy = false
  }
}
```

The `moved` blocks point at the addresses without `[0]`. The submodule moves
them to `[0]` itself.

Terraform creates a new, empty replica bucket. S3 replicates only the objects
that are written after replication is configured. To copy the existing state
objects to the new replica, use S3 Batch Replication. After that, you can
delete the old replica bucket.

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
| <a name="module_context"></a> [context](#module\_context) | git::https://github.com/drape-io/terraform-null-context.git | v1.0.0 |
| <a name="module_primary_s3"></a> [primary\_s3](#module\_primary\_s3) | ./modules/s3 | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Labels from another context, used to seed this module's naming and tags | <pre>object({<br>    enabled    = optional(bool)<br>    group      = optional(string)<br>    tenant     = optional(string)<br>    env        = optional(string)<br>    scope      = optional(string)<br>    attributes = optional(list(string))<br>    tags       = optional(map(string))<br>  })</pre> | n/a | yes |
| <a name="input_enable_lifecycle_rules"></a> [enable\_lifecycle\_rules](#input\_enable\_lifecycle\_rules) | Whether to enable the default S3 lifecycle rules for noncurrent version tiering and cleanup | `bool` | `true` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Allow the S3 bucket to be destroyed and turn off deletion protection on the DynamoDB lock table | `bool` | `false` | no |
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
