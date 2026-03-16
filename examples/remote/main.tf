# This example shows how to configure a project to use the S3 backend
# created by this module. The bucket and dynamodb_table values should
# match the outputs from the tfstate-s3-backend module.
#
# This is a "consumer" example — it doesn't call the module itself,
# it just shows how to point terraform at the backend it created.

resource "null_resource" "example" {
  # Replace this with your actual resources.
  # This is just a placeholder to show the backend config works.
}
