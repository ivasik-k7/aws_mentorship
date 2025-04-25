# ******** DATA SOURCES ********

# data "aws_acm_certificate" "cert" {
#   domain      = "kovtun.dev"
#   types       = ["AMAZON_ISSUED"]
#   most_recent = true
# }

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

# Cost Breakdown:
# VPC: Free (AWS does not charge for creating a VPC).
# Subnets: Free (No additional cost for subnets).
# Internet Gateway: Free (No charge for creation or attachment to a VPC).
# Route Tables: Free (Included with VPC).
# NAT Gateway: $0 (Disabled with enable_nat_gateway = false).
# VPC Flow Logs: $0 (Disabled with enable_flow_logs = false).

module "vpc" {
  source = "../modules/vpc"

  availability_zones   = data.aws_availability_zones.available.names
  public_subnet_cidrs  = ["10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  vpc_cidr             = "10.0.0.0/16"

  identifier = "alb-demo-vpc"

  enable_nat_gateway = false
  enable_flow_logs   = false

  default_tags = var.default_tags
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

# ******** NACL ********

# resource "aws_network_acl" "public_nacl" {
#   vpc_id     = aws_vpc.demo.id
#   subnet_ids = [aws_subnet.public.id]

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 80
#     to_port    = 80
#   }

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 110
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 443
#     to_port    = 443
#   }

#   ingress {
#     protocol   = "icmp"
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     rule_no    = 120
#     from_port  = 8
#     to_port    = 0
#   }

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 130
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 22
#     to_port    = 22
#   }

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 140
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 8080
#     to_port    = 8080
#   }

#   egress {
#     protocol   = "-1"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     to_port    = 0
#   }

#   tags = merge(var.default_tags, {
#     Name = "PublicAccessNACL"
#   })
# }


# ******** EC2 ********


module "ubuntu_instance" {
  source        = "../modules/ec2"
  instance_type = "t2.micro"
  ami_id        = data.aws_ami.ubuntu.id

  associate_public_ip = true
  subnet_ids          = module.vpc.public_subnet_ids
  security_group_ids  = [aws_security_group.web.id]

  key_name = data.aws_key_pair.primary.key_name

  environment  = "dev"
  project_name = "alb-demo"

  instance_count     = 2
  enable_autoscaling = false


  # ebs_volume_size    = 4
  # ebs_volume_type    = "gp2"

  # For ASG:
  # min_size          = 1
  # max_size          = 4
  # desired_capacity  = 2
  # target_group_arns = [aws_lb_target_group.web.arn]
  # health_check_type = "ELB"

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


# ******** ALB ********

resource "aws_alb" "public_app" {
  name               = "demo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = [module.vpc.public_subnet_ids[0]]

  enable_deletion_protection = true
}

resource "aws_lb_target_group" "web" {
  name     = "web-alb-target-group"
  port     = 80
  protocol = "HTTP"

  vpc_id = module.vpc.vpc_id
}

resource "aws_lb_target_group" "web_sticky" {
  name     = "web-alb-target-group-sticky"
  port     = 80
  protocol = "HTTP"

  vpc_id = module.vpc.vpc_id

  stickiness {
    type            = "lb_cookie"
    enabled         = true
    cookie_duration = 86400
  }
}

resource "aws_alb_listener" "http_redirect" {
  load_balancer_arn = aws_alb.public_app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      status_code = "HTTP_301"
      protocol    = "HTTPS"
      port        = "443"
    }
  }
}

# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_alb.public_app.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = data.aws_acm_certificate.cert.arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.web.arn
#   }
# }
