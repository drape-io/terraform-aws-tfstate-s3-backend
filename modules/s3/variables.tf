variable "enabled" {
  type        = bool
  description = "Whether to create the S3 bucket resources"
  default     = true
}

variable "id" {
  type        = string
  description = "The resolved context ID to use for naming (e.g. id_truncated_hash from the context module)"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}

variable "state_suffix" {
  type        = string
  description = "Suffix appended to the bucket name"
  default     = "tfstate"
}

variable "force_destroy" {
  type        = bool
  description = "Allow the S3 bucket to be destroyed. By default we do not want to allow this"
  default     = false
}

variable "sse_algorithm" {
  type        = string
  description = "Server-side encryption algorithm. Use 'aws:kms' for KMS or 'AES256' for S3-managed keys"
  default     = "aws:kms"
}

variable "kms_key_id" {
  type        = string
  description = "KMS key ARN for S3 encryption. If null, the default aws/s3 KMS key is used when sse_algorithm is aws:kms"
  default     = null
}

variable "enable_lifecycle_rules" {
  type        = bool
  description = "Whether to enable the default lifecycle rules for noncurrent version tiering and cleanup"
  default     = true
}
