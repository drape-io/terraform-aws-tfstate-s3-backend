# drape-io/tfstate-s3-backend/aws
## Overview
Terrafor module for provisioning an S3 bucket for the terraform remote state
backend with proper security and locking configured.
drape-io/context/null.


You can use it like this:

```hcl
module "tfstate-backend" {
  source  = "drape-io/tfstate-s3-backend/aws"
  version = "0.0.1"
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
  version = "0.0.1"
  context = merge(local.context, {
    attributes = ["primary"]
  })
  providers = {
    aws.secondary = aws
  }
}
module "secondary-tfstate-backend" {
  source  = "drape-io/tfstate-s3-backend/aws"
  version = "0.0.1"
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

# Destroying
If you try to teardown a module that uses this you will get the error:

```
│ Error: deleting Amazon S3 (Simple Storage) Bucket (drape-customer1-dev-k8s-tfstate): BucketNotEmpty: The bucket you tried to delete is not empty. You must delete all versions in the bucket.
│ 	status code: 409, request id: ec63f05f-f745-4c17-8159-0bc9fc0e1d08, host id: s9lzHYrFp76ZVxRcpX9+5cjAnEH2ROuNkd2BHfIa6UkFVdtjf5mKR3/eTPFvsiP/XV/VLi31234=
```

This is because we protect you from deleting state on accident.  To fix this you
need to set the variable `force_destroy=True`, so:

```hcl
module "primary-tfstate-backend" {
  source  = "drape-io/tfstate-s3-backend/aws"
  version = "0.0.1"
  force_destroy = True
  context = merge(local.context, {
    attributes = ["primary"]
  })
  providers = {
    aws.secondary = aws
  }
}
```

then you need to apply before running the destroy.  You can use a target apply
if you've already destroyed some things:

```bash
tf apply -target module.full.aws_s3_bucket.default
```

Then you can proceed to run `tf destroy`.

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
  version = "0.0.1"
  context = local.context
  providers = {
    aws.secondary = aws.west
  }
}
```