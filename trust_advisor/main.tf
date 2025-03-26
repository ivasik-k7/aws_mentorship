# Needs to have better support plan to have trust advisor rules
# AWS Config charges $0.003 per rule evaluation beyond 10,000 per month. 
# With 5 rules and, say, 100 resources, you’d use 500 evaluations monthly—well under the 10,000 limit.

data "aws_caller_identity" "current" {}

module "config_bucket" {
  source      = "../modules/s3"
  bucket_name = "trust-advisor-config-${data.aws_caller_identity.current.account_id}-${var.environment}"

  restrict_public_buckets = true
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true

  encryption_enabled = true
  versioning_enabled = true

  tags = merge(var.default_tags, {
    Name = "trust-advisor-config-bucket"
  })
}

resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = module.config_bucket.bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowConfigWriteAccess"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${module.config_bucket.bucket_arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid       = "AllowConfigBucketAccess"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = module.config_bucket.bucket_arn
      },
      {
        Sid       = "AllowConfigListBucket"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:ListBucket"
        Resource  = module.config_bucket.bucket_arn
      }
    ]
  })
}

resource "aws_iam_role" "config_role" {
  name = "trust-advisor-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_config_configuration_recorder" "this" {
  name     = "config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  name           = "trust-advisor-delivery-channel"
  s3_bucket_name = module.config_bucket.bucket_id

  s3_key_prefix = "config-data"

  depends_on = [
    aws_config_configuration_recorder.this,
    aws_s3_bucket_policy.config_bucket_policy
  ]
}

resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}


resource "aws_iam_role_policy_attachment" "config_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole" # Updated ARN
}

resource "aws_config_config_rule" "security_group_restricted_ports" {
  name        = "restricted-common-ports"
  description = "Ensures security groups block common vulnerable ports (e.g., FTP, RDP)"

  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
  }

  input_parameters = jsonencode({
    blockedPort1 = "20"   # FTP
    blockedPort2 = "21"   # FTP
    blockedPort3 = "3389" # RDP
  })

  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_config_rule" "iam_user_mfa" {
  name        = "iam-user-mfa-enabled"
  description = "Ensures IAM users have MFA enabled"

  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_MFA_ENABLED"
  }

  scope {
    compliance_resource_types = ["AWS::IAM::User"]
  }

  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_config_rule" "s3_bucket_public_access" {
  name        = "s3-bucket-public-access-check"
  description = "Ensures S3 buckets are not publicly readable or writable"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }

  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_config_rule" "iam_role_least_privilege" {
  name        = "iam-role-least-privilege"
  description = "Ensures IAM roles do not use overly permissive managed policies like AdministratorAccess"

  source {
    owner             = "AWS"
    source_identifier = "IAM_ROLE_MANAGED_POLICY_CHECK"
  }

  input_parameters = jsonencode({
    managedPolicyArns = "arn:aws:iam::aws:policy/AdministratorAccess"
  })

  scope {
    compliance_resource_types = ["AWS::IAM::Role"]
  }

  depends_on = [aws_config_configuration_recorder.this]
}
