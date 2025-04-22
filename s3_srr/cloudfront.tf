
# # I've an CRR of S3 buckets for US and EU
# # How should i configure my cloudfront with route53 www.{domain} to handle content from geo correspondent bucket

# resource "aws_cloudfront_distribution" "cdn" {
#   provider = aws.primary

#   enabled             = true
#   is_ipv6_enabled     = true
#   default_root_object = "index.html"
#   http_version        = "http2"

#   origin {
#     domain_name = aws_s3_bucket_website_configuration.primary.website_endpoint
#     origin_id   = "${var.environment}-s3-origin"

#     connection_attempts = 3
#     connection_timeout  = 10

#     custom_origin_config {
#       origin_protocol_policy = "http-only"
#       http_port              = 80
#       https_port             = 443
#       origin_ssl_protocols   = ["TLSv1.2"]
#     }
#   }

#   default_cache_behavior {
#     target_origin_id = "${var.environment}-s3-origin"
#     cache_policy_id  = data.aws_cloudfront_cache_policy.caching_optimized.id

#     allowed_methods = ["HEAD", "GET"]
#     cached_methods  = ["HEAD", "GET"]


#     viewer_protocol_policy = "allow-all"
#     compress               = true
#   }

#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }

#   viewer_certificate {
#     cloudfront_default_certificate = true
#     minimum_protocol_version       = "TLSv1"
#     ssl_support_method             = "vip"
#   }

#   tags = merge(
#     var.default_tags,
#     {
#       Name        = "${var.environment}-cdn"
#       Environment = var.environment
#     }
#   )
# }
