data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
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

data "aws_key_pair" "primary" {
  key_name = "Primary"
}

resource "aws_security_group" "public" {
  vpc_id      = module.vpc.vpc_id
  name        = "demo-public-mentorship-sg"
  description = "Public security group for demo"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow HTTPS"
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow ICMP pinging"
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
    Name = "demo-public-security-group"
  })
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "vpc-flow-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs_policy" {
  role = aws_iam_role.vpc_flow_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = aws_cloudwatch_log_group.vpc_flow_logs.arn
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flow-logs-${module.vpc.vpc_id}"
  retention_in_days = 7
}

module "cdn_bucket" {
  source = "../modules/s3"

  bucket_name = "mentorship-demo-cloudfront-cdn-${var.environment}"

  versioning_enabled = true
  encryption_enabled = true

  tags = merge(var.default_tags, {
    Name = "mentorship-demo-cloudfront-cdn"
  })
}

module "log_bucket" {
  source = "../modules/s3"

  bucket_name = "mentorship-demo-logs-${var.environment}"

  versioning_enabled = true
  encryption_enabled = true

  object_ownership = "BucketOwnerPreferred"

  tags = merge(var.default_tags, {
    Name = "mentorship-demo-logs-${var.environment}"
  })
}



resource "aws_s3_bucket_lifecycle_configuration" "cdn" {
  bucket = module.cdn_bucket.bucket_id

  rule {
    id     = "ExpireOldObjects"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
  rule {
    id     = "TransitionToIA"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
  rule {
    id     = "ExpireOldVersions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 60
    }
  }
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name        = "cdn.${var.domain}.${var.environment}"
  description = "Origin Access Identity for S3 CDN"

  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "dist" {
  enabled = true

  default_root_object = "index.html"
  origin {
    domain_name              = module.cdn_bucket.bucket_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = module.cdn_bucket.bucket_id
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  logging_config {
    bucket          = module.log_bucket.bucket_domain_name
    prefix          = "cloudfront"
    include_cookies = false
  }

  default_cache_behavior {
    target_origin_id       = module.cdn_bucket.bucket_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["PL"]
    }
  }

  tags = merge(var.default_tags, {
    Name        = "cdn.${var.domain}.${var.environment}"
    Description = "Distribution for ${var.domain} in ${var.environment}"
  })
}


resource "aws_s3_bucket_policy" "cdn" {
  bucket = module.cdn_bucket.bucket_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${module.cdn_bucket.bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.dist.arn
          }
        }
      }
    ]
  })
}



module "vpc" {
  source = "../modules/vpc"

  availability_zones   = data.aws_availability_zones.available.names
  public_subnet_cidrs  = ["10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.4.0/24", "10.0.5.0/24"]
  vpc_cidr             = "10.0.0.0/16"

  project_name = "cloudwatch-golden-signals-demo"
  environment  = "dev"

  enable_nat_gateway = false

  enable_flow_logs      = true
  flow_log_iam_role_arn = aws_iam_role.vpc_flow_logs.arn
  flow_log_destination  = aws_cloudwatch_log_group.vpc_flow_logs.arn

  default_tags = var.default_tags

}

module "ubuntu" {
  source        = "../modules/ec2"
  instance_type = "t2.micro"
  ami_id        = data.aws_ami.ubuntu.id

  associate_public_ip = true
  subnet_ids          = module.vpc.public_subnet_ids
  security_group_ids  = [aws_security_group.public.id]

  key_name = data.aws_key_pair.primary.key_name

  environment  = "dev"
  project_name = "cloudwatch-golden-signals-demo"

  instance_count     = 1
  enable_autoscaling = false

  default_tags = var.default_tags

  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install -y apache2 curl unzip nodejs npm git

    systemctl start apache2
    systemctl enable apache2

    # Personal Landing Page for Ivan Kovtun
    cat << 'HTML' > /var/www/html/index.html
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Ivan Kovtun - The Tech Maestro</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
                font-family: 'Arial', sans-serif;
                background: #000;
                color: white;
                text-align: center;
                overflow: hidden;
            }
            header {
                background: linear-gradient(90deg, #ffcc00, #ff5733);
                padding: 30px;
                box-shadow: 0px 4px 15px rgba(255, 87, 51, 0.5);
            }
            h1 {
                font-size: 2.8em;
                text-transform: uppercase;
                letter-spacing: 3px;
            }
            .container {
                margin: 50px auto;
                max-width: 900px;
                padding: 20px;
            }
            .highlight {
                color: #ffcc00;
                font-weight: bold;
            }
            .tech-list {
                margin-top: 30px;
                font-size: 1.2em;
            }
            .console {
                background: rgba(0, 0, 0, 0.9);
                padding: 20px;
                margin-top: 30px;
                border-radius: 8px;
                box-shadow: 0px 0px 10px rgba(255, 204, 0, 0.7);
                font-family: monospace;
                text-align: left;
                height: 200px;
                overflow: auto;
            }
            .chat-container {
                margin-top: 30px;
                padding: 15px;
                background: rgba(255, 255, 255, 0.1);
                border-radius: 10px;
            }
            input {
                width: 70%;
                padding: 10px;
                font-size: 1em;
                margin-right: 10px;
                border-radius: 5px;
            }
            button {
                padding: 10px;
                font-size: 1em;
                background: #ffcc00;
                border: none;
                cursor: pointer;
                border-radius: 5px;
            }
            footer {
                margin-top: 40px;
                padding: 15px;
                font-size: 0.9em;
                background: rgba(255, 255, 255, 0.1);
            }
        </style>
    </head>
    <body>
        <header>
            <h1>Ivan Kovtun - The Tech Maestro</h1>
        </header>
        <div class="container">
            <p>🚀 Cloud Engineer | DevOps | Gen AI Specialist | Automation Expert</p>
            <p class="tech-list">🔧 Expertise: <span class="highlight">AWS, Azure, VMware, PowerShell, Bash, Python, Kubernetes, Terraform</span></p>

            <div class="console" id="console">
                <p>> Welcome to my cloud-powered AWS server!</p>
            </div>

            <div class="chat-container">
                <p>💬 AI Chatbot - Ask me anything!</p>
                <input type="text" id="chatInput" placeholder="Type a message...">
                <button onclick="sendMessage()">Send</button>
                <div id="chatOutput"></div>
            </div>
        </div>
        <footer>
            <p>💡 Built on AWS | Powered by Apache & Node.js | <a href="https://github.com/ivasik-k7" target="_blank">GitHub</a></p>
        </footer>
        <script>
            let ws = new WebSocket("ws://" + location.hostname + ":8080");

            function logToConsole(message) {
                let consoleDiv = document.getElementById("console");
                consoleDiv.innerHTML += "<p>> " + message + "</p>";
                consoleDiv.scrollTop = consoleDiv.scrollHeight;
            }

            ws.onmessage = function(event) {
                logToConsole("Server: " + event.data);
            };

            function sendMessage() {
                let input = document.getElementById("chatInput");
                let output = document.getElementById("chatOutput");
                ws.send(input.value);
                output.innerHTML += "<p>You: " + input.value + "</p>";
                input.value = "";
            }
        </script>
    </body>
    </html>
    HTML

    # Install & Configure WebSocket Server
    echo 'const WebSocket = require("ws"); 
          const wss = new WebSocket.Server({ port: 8080 }); 
          wss.on("connection", ws => { 
              ws.on("message", msg => ws.send("Echo: " + msg)); 
          });' > /home/ubuntu/server.js

    nohup node /home/ubuntu/server.js > /dev/null 2>&1 &
  EOF
}

resource "aws_lb" "alb" {
  name               = "cloudwatch-demo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public.id]
  subnets            = module.vpc.public_subnet_ids

  tags = {
    Environment = "dev"
    Project     = "cloudwatch-golden-signals-demo"
  }
}

resource "aws_lb_target_group" "alb_tg" {
  name     = "cloudwatch-demo-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

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
    Environment = "dev"
    Project     = "cloudwatch-golden-signals-demo"
  })
}

resource "aws_lb_target_group_attachment" "alb_tg_attachment" {
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = module.ubuntu.instance_ids[0]
  port             = 80
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "demo-signals"
  dashboard_body = jsonencode({
    widgets = flatten([
      [
        for idx, instance_id in module.ubuntu.instance_ids : {
          type   = "metric"
          x      = (idx % 2) * 12
          y      = (floor(idx / 2) + length(module.ubuntu.instance_ids)) * 6
          width  = 12
          height = 6
          properties = {
            metrics = [
              ["AWS/EC2", "NetworkIn", "InstanceId", instance_id],
              ["AWS/EC2", "NetworkOut", "InstanceId", instance_id],
            ]
            view    = "timeSeries"
            stacked = false
            region  = var.region
            title   = "EC2 Traffic - ${instance_id}"
            period  = 300
            stat    = "Sum"
          }
        }
      ],
      {
        type   = "metric"
        x      = 0
        y      = (length(module.ubuntu.instance_ids) * 2) * 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.alb.name],
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "ALB Traffic (Requests)"
          period  = 300
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = (length(module.ubuntu.instance_ids) * 2) * 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.alb.name],
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "ALB Latency (Target Response Time)"
          period  = 300
          stat    = "Average"
        }
      },
      # {
      #   type   = "log"
      #   x      = 0
      #   y      = (length(module.ubuntu.instance_ids) * 2 + 2) * 6
      #   width  = 24
      #   height = 6
      #   properties = {
      #     query         = "stats count(*) by bin(5m)"
      #     region        = var.region
      #     title         = "VPC Flow Logs - Total Bytes Transferred"
      #     view          = "timeSeries"
      #     logGroupNames = [aws_cloudwatch_log_group.vpc_flow_logs.name]
      #   }
      # }
    ])
  })
}


# resource "aws_cloudwatch_metric_alarm" "ec2_cpu_alarm" {
#   count               = length(module.ubuntu.instance_ids)
#   alarm_name          = "ec2-cpu-high-${module.ubuntu.instance_ids[count.index]}"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 2
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/EC2"
#   period              = 300
#   statistic           = "Average"
#   threshold           = 80
#   alarm_description   = "This alarm triggers when CPU utilization exceeds 80% for instance ${module.ubuntu.instance_ids[count.index]}"
#   dimensions = {
#     InstanceId = module.ubuntu.instance_ids[count.index]
#   }
# }
