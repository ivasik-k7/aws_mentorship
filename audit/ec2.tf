
resource "aws_security_group" "web" {
  name   = "audit-web-${var.environment}"
  vpc_id = module.vpc.vpc_id


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.default_tags, {
    Name = "audit-ec2-${var.environment}"
  })
}

module "audit_instance" {
  source = "../modules/ec2"

  key_name      = data.aws_key_pair.primary.key_name
  ami_id        = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  subnet_ids = module.vpc.public_subnet_ids

  environment = var.environment

  ebs_volume_size = 8
  ebs_volume_type = "gp2"

  project_name = "audit"

  security_group_ids = [aws_security_group.web.id]


  user_data = file("${path.module}/userdata.sh")

  iam_role_name = aws_iam_role.audit_role.name

  tags = merge(var.default_tags, {
    Name = "audit-${var.environment}"
  })
}

# resource "aws_iam_role" "audit_role" {
#   name = "audit-ec2-role-${var.environment}"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_policy" "cloudwatch_logs_policy" {
#   name        = "cloudwatch-logs-policy-${var.environment}"
#   description = "Policy for CloudWatch Logs access"
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents",
#           "logs:PutRetentionPolicy"
#         ]
#         Effect   = "Allow"
#         Resource = "arn:aws:logs:*:*:*"
#       },
#       {
#         Action   = "cloudwatch:PutMetricData"
#         Effect   = "Allow"
#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "audit_role_policy" {
#   role       = aws_iam_role.audit_role.name
#   policy_arn = aws_iam_policy.cloudwatch_logs_policy.arn
# }

# resource "aws_iam_instance_profile" "audit_instance_profile" {
#   name = "audit-instance-profile-${var.environment}"
#   role = aws_iam_role.audit_role.name
# }

resource "aws_iam_role" "audit_role" {
  name = "audit-ec2-demo-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "cloudwatch-logs-metrics-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:PutRetentionPolicy"
          ]
          Effect   = "Allow"
          Resource = "arn:aws:logs:*:*:*"
        },
        {
          Action   = "cloudwatch:PutMetricData"
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}
