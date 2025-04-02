# --------------------------------------------------------------------------------
# This file was automatically generated by a merging tool
# DO NOT MODIFY THIS FILE MANUALLY
# Any changes should be made in the original source files
# --------------------------------------------------------------------------------

# ---- Beginning of cloudfront.part.tf ----
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_origin_access_control" "oac" {
  description                       = "Origin Access Identity for S3 CDN"
  name                              = "${var.environment}-s3-cdn-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "dist" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  http_version        = "http2"
  price_class         = "PriceClass_All"

  origin {
    domain_name              = module.cdn_bucket.bucket_regional_domain_name
    origin_id                = "${var.environment}-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id

    connection_attempts = 3
    connection_timeout  = 10
  }

  # origin {
  #   domain_name = aws_lb.web_lb.dns_name
  #   origin_id   = "${var.environment}-alb-origin"

  #   custom_origin_config {
  #     http_port              = 80
  #     https_port             = 443
  #     origin_protocol_policy = "http-only"
  #     origin_ssl_protocols   = ["TLSv1.2"]
  #   }
  # }

  default_cache_behavior {
    target_origin_id = "${var.environment}-s3-origin"
    cache_policy_id  = data.aws_cloudfront_cache_policy.caching_optimized.id

    allowed_methods = ["HEAD", "GET"]
    cached_methods  = ["HEAD", "GET"]


    viewer_protocol_policy = "allow-all"
    compress               = true
  }

  # ordered_cache_behavior {
  #   target_origin_id = "${var.environment}-alb-origin"
  #   cache_policy_id  = data.aws_cloudfront_cache_policy.caching_optimized.id

  #   path_pattern    = "/dynamic/*"
  #   allowed_methods = ["GET", "HEAD", "OPTIONS"]
  #   cached_methods  = ["GET", "HEAD"]

  #   viewer_protocol_policy = "allow-all"
  #   compress               = true
  # }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1"
    ssl_support_method             = "vip"
  }

  tags = merge(var.default_tags, {
    Name = "${var.environment}-cdn"
  })
}

# ---- End of cloudfront.part.tf ----

# ---- Beginning of edge.part.tf ----

resource "aws_iam_role" "edge" {
  name = "cdn-edge-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "edgelambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "edge_policy" {
  name        = "cdn-edge-policy-${var.environment}"
  description = "Policy granting necessary permissions for Lambda@Edge"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:UpdateDistribution",
          "cloudfront:CreateDistribution",
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = module.cdn_bucket.bucket_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "edge_policy_attachment" {
  role       = aws_iam_role.edge.name
  policy_arn = aws_iam_policy.edge_policy.arn
}

resource "local_file" "lambda_edge_code" {
  filename = "${path.module}/edge.py"
  content  = <<EOT
import json
import logging

def handler(event, context):
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    logger.info("Received event: " + json.dumps(event))

    request = event['Records'][0]['cf']['request']
    headers = request['headers']
    
    headers['x-custom-header'] = [{'key': 'X-Custom-Header', 'value': 'CustomHeaderValue'}]

    return request
EOT
}

resource "null_resource" "zip_edge" {
  provisioner "local-exec" {
    command = "zip -j edge.zip edge.py"
  }

  depends_on = [local_file.lambda_edge_code]
}

resource "aws_lambda_function" "edge" {
  filename      = "${path.module}/edge.zip"
  function_name = "cdn-edge-${var.environment}"
  role          = aws_iam_role.edge.arn
  handler       = "edge.handler"
  runtime       = "python3.9"
  publish       = true
}

# ---- End of edge.part.tf ----

# ---- Beginning of s3.part.tf ----

data "aws_caller_identity" "current" {}

module "cdn_bucket" {
  source = "../modules/s3"

  bucket_name = "${var.environment}-cdn-bucket-${data.aws_caller_identity.current.account_id}"

  versioning_enabled = true
  encryption_enabled = true

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  object_ownership = "BucketOwnerPreferred"

  tags = var.default_tags
}

resource "aws_s3_bucket_policy" "cf_policy" {
  bucket = module.cdn_bucket.bucket_id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action   = "s3:GetObject",
        Resource = "${module.cdn_bucket.bucket_arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.dist.id}"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "cdn" {
  bucket = module.cdn_bucket.bucket_id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 60
    }
  }
}

resource "aws_s3_object" "index_html" {
  bucket       = module.cdn_bucket.bucket_id
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
}


# ---- End of s3.part.tf ----

