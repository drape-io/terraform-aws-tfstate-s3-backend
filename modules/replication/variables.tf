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
  description = "Labels from another context, used to seed this module's naming and tags"

  validation {
    condition = alltrue([
      for part in concat(
        [var.context.group, var.context.tenant, var.context.env, var.context.scope],
        var.context.attributes == null ? [] : var.context.attributes,
      ) : part == null || can(regex("^[a-z0-9-]*$", part))
    ])
    error_message = "The context group, tenant, env, scope and attributes may contain only lowercase letters, numbers and hyphens, because they form the S3 bucket name."
  }
}

variable "primary_bucket_name" {
  type        = string
  description = "The name of the primary S3 bucket to replicate from"
}

variable "primary_bucket_arn" {
  type        = string
  description = "The ARN of the primary S3 bucket to replicate from"
}

variable "force_destroy" {
  type        = bool
  description = "Allow the S3 bucket to be destroyed"
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
