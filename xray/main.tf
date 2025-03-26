# Traces Recorded: $0.000005 per trace ($5 per million) after the first 100,000.
# Traces Retrieved: $0.00005 per trace ($50 per million) after the first 100,000.
# Traces Scanned: $0.0000005 per trace ($0.50 per million) after the first 1,000,000.

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "../modules/vpc"

  project_name = "xray"

  availability_zones = data.aws_availability_zones.available.names

  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24"]

  environment = var.environment

  enable_nat_gateway = false
  enable_flow_logs   = false

  default_tags = merge(var.default_tags, {
    Name = "xray-vpc"
  })
}


# resource "aws_security_group" "http" {
#   vpc_id      = module.vpc.vpc_id
#   name        = "xray-public-http-sg"
#   description = "HTTP security group for X-Ray demo"

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = merge(var.default_tags, {
#     Name = "demo-public-security-group"
#   })
# }

resource "aws_xray_group" "main" {
  filter_expression = "service(\"demo\")"
  group_name        = "demo-group"
  tags = merge(var.default_tags, {
    Name = "demo-group"
  })
}

resource "aws_xray_sampling_rule" "main" {
  rule_name = "xray-demo-sampling-rule"

  priority       = 100
  version        = 1
  reservoir_size = 1
  fixed_rate     = 0.05

  resource_arn = "*"
  service_name = "*"
  service_type = "*"
  host         = "*"
  http_method  = "*"
  url_path     = "*"

  attributes = merge(var.default_tags, {
    Name        = "demo-sampling-rule"
    Environment = var.environment
  })
}
