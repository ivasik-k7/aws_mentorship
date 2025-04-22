module "primary_bucket" {
  source = "../modules/s3"

  bucket_name = "${var.environment}-primary-bucket-${data.aws_caller_identity.current.account_id}"

  versioning_enabled = true
  encryption_enabled = true


  sse_algorithm = "AES256"

  tags = merge(
    var.default_tags,
    {
      Name        = "${var.environment}-primary-bucket"
      Environment = var.environment
    }
  )
}

module "replica_bucket" {
  source = "../modules/s3"

  providers = {
    aws = aws.alternate
  }

  bucket_name = "${var.environment}-replica-bucket-${data.aws_caller_identity.current.account_id}"

  versioning_enabled = true
  encryption_enabled = true

  sse_algorithm = "AES256"

  tags = merge(var.default_tags, {
    Name        = "${var.environment}-replica-bucket"
    Environment = var.environment
  })
}


resource "aws_iam_role" "crr_role" {
  name = "s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "replication" {
  name = "s3-replication-policy"
  role = aws_iam_role.crr_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SourceBucketPermissions"
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
          "s3:ListBucket"
        ]
        Resource = [
          "${module.primary_bucket.bucket_arn}/*",
          "${module.primary_bucket.bucket_arn}"
        ]
      },
      {
        Sid    = "DestinationBucketPermissions"
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateTags",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ]
        Resource = [
          "${module.replica_bucket.bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  bucket = module.primary_bucket.bucket_id
  role   = aws_iam_role.crr_role.arn

  rule {
    id     = "replication-rule"
    status = "Enabled"

    destination {
      bucket        = module.replica_bucket.bucket_arn
      storage_class = "STANDARD"
    }
  }
}

resource "aws_s3_object" "index_html" {
  bucket       = module.primary_bucket.bucket_id
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
}
