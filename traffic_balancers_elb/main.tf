# Cost Considerations
# Free Tier: 
#   Covers CLB/ALB (15 LCUs), EC2 t2.micro (750 hours/month), CloudWatch basic monitoring.
# NLB Costs:
#  ~$0.0225/hour + $0.008/LCU-hour.
#   Limit testing to a few hours and destroy resources with terraform destroy afterward.

# ******** DATA SOURCES ********


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

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_key_pair" "primary" {
  key_name = "Primary"
}

# ******** VPC ********

module "vpc" {
  source = "../modules/vpc"

  availability_zones   = data.aws_availability_zones.available.names
  public_subnet_cidrs  = ["10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  vpc_cidr             = "10.0.0.0/16"

  project_name = "elb-demo"
  environment  = "dev"

  enable_nat_gateway = false
  enable_flow_logs   = false

  default_tags = var.default_tags
}

# ******** ELB ********

resource "aws_lb" "nlb" {
  name               = "demo-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = module.vpc.public_subnet_ids

  enable_cross_zone_load_balancing = false

  tags = merge(var.default_tags, {
    Name = "demo-nlb"
  })
}

resource "aws_lb_target_group" "nlb_tcp_tg" {
  name        = "nlb-tcp-tg"
  port        = 80
  protocol    = "TCP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    protocol            = "TCP"
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = merge(var.default_tags, {
    Name = "nlb-tcp-tg"
  })
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_tcp_tg.arn
  }
}


# ******** SG ********

resource "aws_security_group" "web" {
  vpc_id      = module.vpc.vpc_id
  name        = "demo-mentorship-sg"
  description = "Security group for demo mentorship"

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
    Name = "PublicAccessSG"
  })
}

# ******** EC2 ********

resource "aws_instance" "amazon_linux" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  security_groups             = [aws_security_group.web.id]
  subnet_id                   = module.vpc.public_subnet_ids[0]
  associate_public_ip_address = true

  key_name = data.aws_key_pair.primary.key_name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd

    cat << 'HTML' > /var/www/html/index.html
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Ivan Kovtun - AWS ELB Guide</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                background-color: #f4f4f4;
                margin: 0;
                padding: 0;
                text-align: center;
            }
            header {
                background: #333;
                color: white;
                padding: 20px;
                font-size: 24px;
            }
            .content {
                max-width: 800px;
                margin: 20px auto;
                padding: 20px;
                background: white;
                box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
                border-radius: 8px;
                text-align: left;
            }
            h2 {
                color: #333;
            }
            p {
                line-height: 1.6;
            }
            footer {
                margin-top: 20px;
                padding: 10px;
                background: #333;
                color: white;
                font-size: 14px;
            }
        </style>
    </head>
    <body>
        <header>Welcome to Ivan Kovtun's AWS ELB Guide</header>
        <div class="content">
            <h2>Understanding AWS Elastic Load Balancer (ELB)</h2>
            <p>AWS Elastic Load Balancer (ELB) automatically distributes incoming application traffic across multiple targets, such as EC2 instances, containers, and IP addresses. This improves fault tolerance, availability, and performance.</p>
            <h3>Types of AWS Load Balancers</h3>
            <ul>
                <li><b>Application Load Balancer (ALB)</b> - Best for HTTP/HTTPS traffic, supports path-based and host-based routing.</li>
                <li><b>Network Load Balancer (NLB)</b> - Designed for high-performance TCP/UDP traffic with ultra-low latency.</li>
                <li><b>Classic Load Balancer (CLB)</b> - The legacy load balancer, supporting basic load balancing features.</li>
            </ul>
            <h3>Key Features of ELB</h3>
            <ul>
                <li>Automatic scaling based on traffic load.</li>
                <li>Health checks to ensure traffic is sent to healthy instances.</li>
                <li>Integration with AWS Auto Scaling for high availability.</li>
                <li>SSL/TLS termination for secure communication.</li>
            </ul>
            <p>For more details, visit the <a href="https://aws.amazon.com/elasticloadbalancing/">AWS ELB documentation</a>.</p>
        </div>
        <footer>&copy; 2025 Ivan Kovtun | AWS Cloud Enthusiast</footer>
    </body>
    </html>
    HTML

    systemctl restart httpd

    EOF

  tags = merge(var.default_tags, {
    "Name"        = "amazon-linux-elb-test-server"
    "Description" = "Amazon Linux instance for ELB testing"
  })
}


resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.nlb_tcp_tg.arn
  target_id        = aws_instance.amazon_linux.id
  port             = 80
}
