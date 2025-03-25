variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the S3 bucket"
  type        = map(string)
  default     = {}
}

variable "object_ownership" {
  description = "Object ownership setting (BucketOwnerPreferred, ObjectWriter, BucketOwnerEnforced)"
  type        = string
  default     = "BucketOwnerEnforced"
}

variable "block_public_acls" {
  description = "Whether to block public ACLs"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Whether to block public bucket policies"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Whether to ignore public ACLs"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Whether to restrict public bucket access"
  type        = bool
  default     = true
}

variable "versioning_enabled" {
  description = "Whether versioning is enabled"
  type        = bool
  default     = false
}

variable "encryption_enabled" {
  description = "Whether server-side encryption is enabled"
  type        = bool
  default     = true
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm (AES256 or aws:kms)"
  type        = string
  default     = "AES256"
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (required if sse_algorithm is aws:kms)"
  type        = string
  default     = null
}


variable "cors_rules" {
  description = "List of CORS rules for the bucket"
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  default = []
}

variable "logging_enabled" {
  description = "Whether logging is enabled"
  type        = bool
  default     = false
}

variable "logging_target_bucket" {
  description = "Target bucket for logging (required if logging_enabled is true)"
  type        = string
  default     = ""
}

variable "logging_target_prefix" {
  description = "Prefix for log objects in the target bucket"
  type        = string
  default     = "logs/"
}

variable "bucket_policy" {
  description = "Custom bucket policy in JSON format"
  type        = string
  default     = ""
}
