data "aws_availability_zones" "this" {
  state = "available"
}

data "aws_key_pair" "primary" {
  key_name = "Primary"
}


data "aws_caller_identity" "current" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

### RESOURCES ###
## Security Group ##
resource "aws_security_group" "web" {
  vpc_id      = module.vpc.vpc_id
  name        = "${var.environment}-web-sg"
  description = "Security group for web servers"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.default_tags, {
    Name = "PublicAccessSG"
  })
}
## VPC ##
module "vpc" {
  source = "../modules/vpc"

  availability_zones = data.aws_availability_zones.this.names

  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.2.0/24", "10.0.3.0/24", ]
  private_subnet_cidrs = ["10.0.4.0/24"]

  environment  = var.environment
  project_name = "ec2"

  enable_nat_gateway = false
  enable_flow_logs   = false

  default_tags = merge(var.default_tags, {
    Name = "${var.environment}-vpc"
  })
}
#
# EC2 Instance ##
resource "aws_launch_template" "web_template" {
  name = "${var.environment}-web-template"

  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  key_name = data.aws_key_pair.primary.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web.id]
  }

  lifecycle {
    create_before_destroy = true
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash

    yum update -y
    yum install -y httpd

    systemctl start httpd
    systemctl enable httpd

    echo "<h1>Welcome to the ${var.environment} Environment</h1>" > /var/www/html/index.html

    chown apache:apache /var/www/html/index.html
    chmod 644 /var/www/html/index.html
    EOF
  )
}

## Load Balancer ##
resource "aws_lb" "web_lb" {
  name               = "${var.environment}-web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = module.vpc.public_subnet_ids

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "web_tg" {
  vpc_id   = module.vpc.vpc_id
  name     = "${var.environment}-web-tg"
  protocol = "HTTP"
  port     = 80

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(var.default_tags, {
    Name = "${var.environment}-web-tg"
  })
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name = "${var.environment}-web-asg"

  min_size         = 1
  max_size         = 3
  desired_capacity = 1
  target_group_arns = [
    aws_lb_target_group.web_tg.arn
  ]
  vpc_zone_identifier = module.vpc.private_subnet_ids

  launch_template {
    id      = aws_launch_template.web_template.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }
}

### CDN ###
## S3 Bucket ##

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

resource "aws_s3_bucket_policy" "cdn_policy" {
  bucket = module.cdn_bucket.bucket_id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "${module.cdn_bucket.bucket_arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.static.arn
        }
      }
    }]
  })
}


resource "aws_s3_object" "index_html" {
  depends_on = [aws_s3_bucket_policy.cdn_policy]


  bucket       = module.cdn_bucket.bucket_id
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"
}


## CloudFront Distribution ##

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

  origin {
    domain_name = aws_lb.web_lb.dns_name
    origin_id   = "${var.environment}-alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id = "${var.environment}-s3-origin"
    cache_policy_id  = data.aws_cloudfront_cache_policy.caching_optimized.id

    allowed_methods = ["HEAD", "GET"]
    cached_methods  = ["HEAD", "GET"]


    viewer_protocol_policy = "allow-all"
    compress               = true
  }

  ordered_cache_behavior {
    target_origin_id = "${var.environment}-alb-origin"
    cache_policy_id  = data.aws_cloudfront_cache_policy.caching_optimized.id

    path_pattern    = "/dynamic/*"
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    viewer_protocol_policy = "allow-all"
    compress               = true
  }

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
