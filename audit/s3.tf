module "audit_bucket" {
  source = "../modules/s3"

  bucket_name = "${var.environment}-audit-bucket-${data.aws_caller_identity.current.account_id}"

  force_destroy_enabled = true
  versioning_enabled    = true
  encryption_enabled    = true

  object_ownership = "BucketOwnerPreferred"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = merge(var.default_tags, {
    Name = "audit-bucket-${var.environment}"
  })
}


resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = module.audit_bucket.bucket_id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = "s3:GetBucketAcl",
        Resource  = module.audit_bucket.bucket_arn
      },
      {
        Sid       = "AWSCloudTrailWrite",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = "s3:PutObject",
        Resource  = "${module.audit_bucket.bucket_arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}
