output "cloudfront_url" {
  value = aws_cloudfront_distribution.dist.domain_name
}
