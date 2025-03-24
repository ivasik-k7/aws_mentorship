resource "aws_s3_bucket" "cdn" {
  force_destroy = true
  bucket        = "cdn.${var.domain}.${var.environment}"


  tags = merge(var.default_tags, {
    Name = "cdn.${var.domain}.${var.environment}"
  })
}

resource "aws_s3_bucket_versioning" "cdn" {
  bucket = aws_s3_bucket.cdn.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cdn" {
  bucket = aws_s3_bucket.cdn.bucket

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 60
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cdn" {
  bucket = aws_s3_bucket.cdn.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cdn" {
  bucket = aws_s3_bucket.cdn.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}



resource "aws_s3_bucket_policy" "cf_policy" {
  bucket = aws_s3_bucket.cdn.bucket

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.cdn.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.dist.arn
        }
      }
    }]
  })
}


# lambda@edge
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
        Resource = aws_s3_bucket.cdn.arn
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


resource "aws_cloudfront_origin_access_control" "oac" {
  name        = "cdn.${var.domain}.${var.environment}"
  description = "Origin Access Identity for CDN"

  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "dist" {
  enabled = true

  default_root_object = "index.html"
  origin {
    domain_name              = aws_s3_bucket.cdn.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = aws_s3_bucket.cdn.bucket
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  default_cache_behavior {
    target_origin_id       = aws_s3_bucket.cdn.bucket
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "blacklist"
      locations        = ["UA"]
    }
  }

  tags = merge(var.default_tags, {
    Name        = "cdn.${var.domain}.${var.environment}"
    Description = "Distribution for ${var.domain} in ${var.environment}"
  })
}
