data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}

locals {
  vpc_id = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default.id
}

resource "aws_sqs_queue" "main" {
  count = var.is_create_sqs ? 1 : 0

  name                       = var.sqs_queue_name
  delay_seconds              = 0
  max_message_size           = 262144 # max 256kb
  message_retention_seconds  = 86400  # max 1 day
  receive_wait_time_seconds  = 0
  visibility_timeout_seconds = 30

  tags = merge(var.default_tags, {
    "name" : "sqs-queue"
  })
}


resource "aws_sns_topic" "main" {
  count = var.is_create_sns ? 1 : 0

  name = var.sns_topic_name

  delivery_policy = jsonencode({
    "http" : {
      "defaultHealthyRetryPolicy" : {
        "minDelayTarget" : 20,
        "maxDelayTarget" : 20,
        "numRetries" : 3,
        "numMaxDelayRetries" : 0,
        "numNoDelayRetries" : 0,
        "numMinDelayRetries" : 0,
        "backoffFunction" : "linear"
      },
      "disableSubscriptionOverrides" : false
    }
  })

  tags = merge(var.default_tags, {
    "name" : "sns-queue"
  })
}


resource "aws_vpc_endpoint" "sns" {
  count = var.is_create_sns ? 1 : 0

  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.region}.sns"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.default.ids
  private_dns_enabled = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "sns:Publish",
          "sns:Subscribe"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceVpce" = "${local.vpc_id}"
          }
        }
      }
    ]
  })

  tags = merge(var.default_tags, {
    Name = "sns-interface-endpoint"
  })
}


resource "aws_vpc_endpoint" "sqs" {
  count = var.is_create_sqs ? 1 : 0

  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.region}.sqs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.default.ids
  private_dns_enabled = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.main[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceVpce" = "${local.vpc_id}"
          }
        }
      }
    ]
  })

  tags = merge(var.default_tags, {
    Name = "sqs-interface-endpoint"
  })
}
