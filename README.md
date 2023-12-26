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
}
```

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
}
module "secondary-tfstate-backend" {
  source  = "drape-io/tfstate-s3-backend/aws"
  version = "0.0.1"
  context = merge(local.context, {
    attributes = ["secondary"]
  })
}
```

Which will create two buckets:

- drape-dev-primary-tfstate
- drape-dev-secondary-tfstate
