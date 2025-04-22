# resource "aws_route53_record" "geo_eu" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = "www.${var.domain}"
#   type    = "A"

#   set_identifier = "eu-endpoint"

#   geolocation_routing_policy {
#     continent = "EU"
#   }

#   alias {
#     name                   = aws_cloudfront_distribution.cdn.domain_name
#     zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
#     evaluate_target_health = false
#   }
# }

# resource "aws_route53_record" "geo_us" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = "www.${var.domain}"
#   type    = "A"

#   set_identifier = "us-endpoint"

#   geolocation_routing_policy {
#     continent = "US"
#   }

#   alias {
#     name                   = aws_cloudfront_distribution.cdn.domain_name
#     zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
#     evaluate_target_health = false
#   }
# }


# resource "aws_route53_record" "geo_default" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = "www.${var.domain}"
#   type    = "A"

#   set_identifier = "default-endpoint"

#   geolocation_routing_policy {}

#   alias {
#     name                   = aws_cloudfront_distribution.cdn.domain_name
#     zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
#     evaluate_target_health = false
#   }
# }
