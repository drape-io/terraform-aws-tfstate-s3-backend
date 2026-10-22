# Changelog

## 1.0.0

### Breaking changes

- Replication moved from the `enable_replication` variable to the
  `modules/replication` submodule. The root module no longer needs an
  `aws.secondary` provider. The replica bucket is now `<id>-replica-tfstate`
  instead of `<id>-2-tfstate`. The policy attachment is now an
  `aws_iam_role_policy_attachment`. Follow "Upgrading from 0.0.x" in the
  README to move the replication resources without destroying them.
- The default `sse_algorithm` is `aws:kms` with the AWS managed `aws/s3` key.
  Before, the bucket always used `AES256`. Terraform updates the bucket
  encryption in place. Set `sse_algorithm = "AES256"` to keep the old
  behavior.
- The DynamoDB lock table has deletion protection, unless
  `force_destroy = true`.
- Ids longer than 55 characters are shortened with a hash, so the bucket name
  fits in 63 characters and keeps the `-tfstate` suffix. Before, the limit had
  no effect and the name was cut off, which could drop the suffix or give two
  buckets the same name. Bucket and table names change for those ids, so
  Terraform replaces those resources. Names of ids up to 55 characters do not
  change.
- The context fields `group`, `tenant`, `env`, `scope` and `attributes` can
  contain only lowercase letters, numbers and hyphens. Other values fail at
  plan. Before, S3 rejected them at apply.
- `kms_key_id` with an `sse_algorithm` other than `aws:kms` or
  `aws:kms:dsse` fails at plan. Before, S3 rejected it at apply.
- The module uses drape-io/terraform-null-context 1.0.0. Tag changes on
  existing buckets, tables and IAM resources, all updated in place:
  - The `environment` tag of an `env` code expands to its full name, for
    example `sbx` to `sandbox`.
  - Tags generated from the context override tags with the same key in
    `context.tags`.
  - The `random_string` resources of the context module leave the state.
    No cloud resource changes.
- The module needs Terraform 1.6 or later and AWS provider 5.0 or later. It no
  longer needs the `hashicorp/random` provider.

### Added

- Each bucket has a bucket policy that denies requests not made over TLS. It
  replaces any policy that the bucket has.
- The lifecycle rules have an empty `filter`. AWS provider 5.x warns that a
  rule without one will become an error.
- The `modules/s3` submodule has a `region` output.

### Fixes

- The replication submodule respects `context.enabled`. Before, a disabled
  context failed at plan.
- The replication configuration waits until versioning is on for the replica
  bucket.
- The replication IAM role name fits in the 64 character IAM limit.
- `backend_config` takes the region from the bucket. The `aws_region` data
  source attribute it used is deprecated in AWS provider 6.
- The full example validates again. The remote example locks state.
- CI validates the full example and runs the replication tests.
