# Consumer example. It does not call the module. It points a project at the
# backend that the module created, so the bucket and dynamodb_table values
# must match the module's outputs.

resource "null_resource" "example" {
  # Placeholder to show that the backend works. Replace it with your resources.
}
