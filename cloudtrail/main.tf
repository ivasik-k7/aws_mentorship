# get account id
data "aws_caller_identity" "current" {}

module "trail_bucket" {
  source = "../modules/s3"

  bucket_name = "cloudtrail-${var.environment}-${data.aws_caller_identity.current.account_id}"

  encryption_enabled = true
  versioning_enabled = true

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  object_ownership = "BucketOwnerEnforced"

  tags = merge(var.default_tags, {
    Name        = "cloudtrail-${var.environment}"
    Environment = var.environment
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "trail" {
  bucket = module.trail_bucket.bucket_id

  rule {
    id     = "archive-to-glacier"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 3650
    }
  }

}




resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = module.trail_bucket.bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = module.trail_bucket.bucket_arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${module.trail_bucket.bucket_arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "main" {
  depends_on = [aws_s3_bucket_policy.cloudtrail_policy]

  name           = "cloudtrail-main-${var.environment}"
  s3_bucket_name = module.trail_bucket.bucket_id

  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  insight_selector {
    insight_type = "ApiCallRateInsight"
  }

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = merge(var.default_tags, {
    Name        = "cloudtrail-${var.environment}"
    Environment = var.environment
  })
}
