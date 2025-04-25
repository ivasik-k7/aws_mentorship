data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "current" {
  state = "available"
}

data "aws_acm_certificate" "certificate" {
  domain   = var.domain_name
  statuses = ["ISSUED"]

  most_recent = true
}

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

locals {
  image_name          = "nginx"
  image_tag           = "latest"
  app_name            = "${var.environment}-nginx-service"
  ecs_task_policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ssl_policy_name     = "ELBSecurityPolicy-2016-08"
}
