output "bucket_id" {
  description = "The ID of the S3 bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket regional domain name"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_region" {
  description = "The AWS region this bucket resides in"
  value       = aws_s3_bucket.this.region
}

output "bucket_ownership_controls" {
  description = "The object ownership setting for the bucket"
  value       = aws_s3_bucket_ownership_controls.this.rule[0].object_ownership
}

output "public_access_block_configuration" {
  description = "The public access block configuration for the bucket"
  value = {
    block_public_acls       = aws_s3_bucket_public_access_block.this.block_public_acls
    block_public_policy     = aws_s3_bucket_public_access_block.this.block_public_policy
    ignore_public_acls      = aws_s3_bucket_public_access_block.this.ignore_public_acls
    restrict_public_buckets = aws_s3_bucket_public_access_block.this.restrict_public_buckets
  }
}

output "versioning_status" {
  description = "The versioning status of the bucket"
  value       = aws_s3_bucket_versioning.this.versioning_configuration[0].status
}

output "cors_configuration" {
  description = "The CORS configuration for the bucket"
  value       = length(var.cors_rules) > 0 ? aws_s3_bucket_cors_configuration.this[0].cors_rule : []
}

output "logging_configuration" {
  description = "The logging configuration for the bucket"
  value = var.logging_enabled ? {
    target_bucket = aws_s3_bucket_logging.this[0].target_bucket
    target_prefix = aws_s3_bucket_logging.this[0].target_prefix
  } : null
}

output "bucket_policy" {
  description = "The bucket policy applied to the S3 bucket"
  value       = var.bucket_policy != "" ? aws_s3_bucket_policy.this[0].policy : null
}
