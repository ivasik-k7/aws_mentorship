data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# data "aws_acm_certificate" "certificate" {
#   domain      = var.domain_name
#   statuses    = ["ISSUED"]
#   types       = ["AMAZON_ISSUED"]
#   most_recent = true
# }

# data "aws_route53_zone" "main" {
#   name         = var.domain_name
#   private_zone = false
# }


