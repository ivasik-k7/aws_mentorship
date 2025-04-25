resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${local.app_name}"
  retention_in_days = 7

  tags = merge(var.default_tags, {
    Name = "${local.app_name}-ecs-log-group"
  })
}
