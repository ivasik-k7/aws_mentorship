data "aws_route53_zone" "main" {
  name         = var.domain
  private_zone = false
}

data "aws_acm_certificate" "certificate" {
  domain   = var.domain
  statuses = ["ISSUED"]

  most_recent = true
}

data "aws_caller_identity" "current" {}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}
