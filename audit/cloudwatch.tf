resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "primary-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization",
              "InstanceId",
              module.audit_instance.instance_ids[0],
              { "label" : "CPU Utilization", "color" : "#1f77b4" }
            ],
            [
              "CWAgent",
              "mem_used",
              "InstanceId",
              module.audit_instance.instance_ids[0],
              { "label" : "Memory Used", "color" : "#ff7f0e" }
            ],
            [
              "CWAgent",
              "mem_total",
              "InstanceId",
              module.audit_instance.instance_ids[0],
              { "label" : "Memory Total", "color" : "#2ca02c" }
            ],
            [
              "CWAgent",
              "disk_used_percent",
              "InstanceId",
              module.audit_instance.instance_ids[0],
              "device", "xvda1",
              "fstype", "xfs",
              "path", "/",
              { "label" : "Disk Used %", "color" : "#d62728" }
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Instance Resource Utilization"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            [
              "CWAgent",
              "net_packets_recv",
              "InstanceId",
              module.audit_instance.instance_ids[0],
              { "label" : "Packets Received", "color" : "#9467bd" }
            ],
            [
              "CWAgent",
              "net_packets_sent",
              "InstanceId",
              module.audit_instance.instance_ids[0],
              { "label" : "Packets Sent", "color" : "#8c564b" }
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Network Activity"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 18
        width  = 24
        height = 6
        properties = {
          query  = <<QUERY
          SOURCE '/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log' | 
          filter @message like /ERROR/ or @message like /WARN/ |
          display @timestamp, @message |
          sort @timestamp desc |
          limit 20
          QUERY
          region = var.region
          title  = "CloudWatch Agent Logs (Recent Errors/Warnings)"
          view   = "table"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "apache_access" {
  name              = "/var/log/httpd/access_log"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "apache_error" {
  name              = "/var/log/httpd/error_log"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "cloudwatch_agent" {
  name              = "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
  retention_in_days = 7
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "high-cpu-utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  dimensions = {
    InstanceId = module.audit_instance.instance_ids[0]
  }
}

resource "aws_cloudwatch_metric_alarm" "status_check_failed" {
  alarm_name          = "status-check-failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors ec2 status check failed"
  dimensions = {
    InstanceId = module.audit_instance.instance_ids[0]
  }
}
