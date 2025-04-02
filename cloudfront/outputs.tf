# CloudFront Distribution Outputs
output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.dist.id
}

output "cloudfront_distribution_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.dist.domain_name
}

output "cloudfront_distribution_arn" {
  description = "The ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.dist.arn
}

# S3 Bucket Outputs
output "cdn_bucket_name" {
  description = "The name of the S3 bucket used for the CDN"
  value       = module.cdn_bucket.bucket_id
}

output "cdn_bucket_arn" {
  description = "The ARN of the S3 bucket used for the CDN"
  value       = module.cdn_bucket.bucket_arn
}

output "cdn_bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket"
  value       = module.cdn_bucket.bucket_regional_domain_name
}

# Lambda@Edge Outputs
output "lambda_edge_function_name" {
  description = "The name of the Lambda@Edge function"
  value       = aws_lambda_function.edge.function_name
}

output "lambda_edge_function_arn" {
  description = "The ARN of the Lambda@Edge function"
  value       = aws_lambda_function.edge.arn
}

output "lambda_edge_function_version" {
  description = "The version of the Lambda@Edge function"
  value       = aws_lambda_function.edge.version
}

