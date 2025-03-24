data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "public_subnets" {
  for_each = toset(data.aws_subnets.default_vpc_subnets.ids)
  id       = each.value
}

locals {
  public_subnets = [
    for subnet in data.aws_subnet.public_subnets : subnet.id
    if subnet.map_public_ip_on_launch == true
  ]
}



resource "aws_lb" "demo" {
  name               = "${var.environment}-lb-waf"
  load_balancer_type = "application"

  internal                         = false
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = false

  subnets = local.public_subnets
}


resource "aws_lb_listener" "mock" {
  load_balancer_arn = aws_lb.demo.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      status_code  = 200
      content_type = "text/plain"
      message_body = "Hello, World!"
    }
  }

  tags = merge(var.default_tags, {
    Name        = "${var.environment}-lb-listener"
    Environment = var.environment
  })
}


resource "aws_cloudfront_distribution" "waf_dist" {
  origin {
    domain_name = "example.com"
    origin_id   = "example-origin"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = "example-origin"
    viewer_protocol_policy = "allow-all"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
  }

  restrictions {
    geo_restriction {
      restriction_type = "blacklist"
      locations        = ["UA"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  web_acl_id = aws_wafv2_web_acl.cloudfront_acl.arn
}


resource "aws_wafv2_ip_set" "lb_set" {
  name               = "${var.environment}-lb-ip-set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["203.0.113.0/24"]
}

resource "aws_wafv2_web_acl" "cloudfront_acl" {
  name        = "${var.environment}-waf-cloudfront-acl"
  description = "WAF CloudFront ACL for ${var.environment} environment"
  scope       = "CLOUDFRONT"

  visibility_config {
    metric_name                = "${var.environment}-waf-acl-cloudfront-metrics"
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled   = true
  }

  default_action {
    allow {}
  }

  rule {
    name     = "RateLimitRule"
    priority = 1
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = 100
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit-metric"
      sampled_requests_enabled   = true
    }
  }

  tags = merge(var.default_tags, {
    Name        = "${var.environment}-waf-cloudfront-acl"
    Environment = var.environment
  })
}



resource "aws_wafv2_web_acl" "lb_acl" {
  name        = "${var.environment}-waf-lb-acl"
  description = "WAF LB ACL for ${var.environment} environment"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "RateLimitRule"
    priority = 1
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = 100
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "BlockBadIP"
    priority = 2
    action {
      block {}
    }
    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.lb_set.arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "block-ip-metric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.environment}-waf-lb-metric"
    sampled_requests_enabled   = true
  }

  tags = merge(var.default_tags, {
    Name        = "${var.environment}-waf-lb-acl"
    Environment = var.environment
  })
}

resource "aws_wafv2_web_acl_association" "lb_assoc" {
  resource_arn = aws_lb.demo.arn
  web_acl_arn  = aws_wafv2_web_acl.lb_acl.arn
}



# CloudWatch

resource "aws_cloudwatch_log_group" "lb" {
  name              = "/aws/wafv2/${var.environment}/lb"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "cloudfront" {
  name = "/aws/wafv2/${var.environment}/cloudfront"
}

resource "aws_wafv2_web_acl_logging_configuration" "lb" {
  log_destination_configs = [aws_cloudwatch_log_group.lb.arn]
  resource_arn            = aws_wafv2_web_acl.lb_acl.arn
}

resource "aws_wafv2_web_acl_logging_configuration" "cloudfront" {
  log_destination_configs = [aws_cloudwatch_log_group.cloudfront.arn]
  resource_arn            = aws_wafv2_web_acl.cloudfront_acl.arn
}
