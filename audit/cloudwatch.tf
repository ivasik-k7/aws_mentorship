resource "aws_cloudwatch_log_group" "system_logs" {
  for_each = toset([
    "SystemLogs/secure",
    "SystemLogs/dmesg"
  ])

  name              = each.key
  retention_in_days = 1

  tags = merge(var.default_tags, {
    Name = "SystemLogs"
  })
}
