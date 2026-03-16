# This was copied from `drape-io/terraform-null-context` since it'll be passed
# along to it.
variable "context" {
  type = object({
    enabled    = optional(bool)
    group      = optional(string)
    tenant     = optional(string)
    env        = optional(string)
    scope      = optional(string)
    attributes = optional(list(string))
    tags       = optional(map(string))
  })
  description = <<-EOT
    Used to pass an object of any of the variables used to this module.  It is
    used to seed the module with labels from another context.
  EOT
}

variable "force_destroy" {
  type        = bool
  description = "Allow the S3 bucket to be destroyed. By default we do not want to allow this"
  default     = false
}

variable "enable_replication" {
  type        = bool
  description = "This enables replication to a secondary region"
  default     = false
}

variable "sse_algorithm" {
  type        = string
  description = "Server-side encryption algorithm for S3. Use 'aws:kms' for KMS or 'AES256' for S3-managed keys"
  default     = "aws:kms"
}

variable "kms_key_id" {
  type        = string
  description = "KMS key ARN for S3 encryption. If null, the default aws/s3 KMS key is used when sse_algorithm is aws:kms"
  default     = null
}

variable "enable_lifecycle_rules" {
  type        = bool
  description = "Whether to enable the default S3 lifecycle rules for noncurrent version tiering and cleanup"
  default     = true
}