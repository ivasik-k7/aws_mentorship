# ******** DATA SOURCES ********

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

# data "aws_acm_certificate" "cert" {
#   domain   = "mentorship-test.com"
#   statuses = ["ISSUED"]
# }


# ******** VPC ********

resource "aws_vpc" "demo" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.default_tags, {
    Name = "Demo VPC"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.demo.id

  tags = merge(var.default_tags, {
    Name = "Demo IGW"
  })
}

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.demo.id

  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false

  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(var.default_tags, {
    Name = "Private Subnet"
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.demo.id

  tags = merge(var.default_tags, {
    Name = "Private Route Table"
  })
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.demo.id

  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]


  tags = merge(var.default_tags, {
    Name = "Public Subnet"
  })
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.default_tags, {
    Name = "Public Route Table"
  })
}


resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ******** SG ********

resource "aws_security_group" "web" {
  vpc_id      = aws_vpc.demo.id
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

# ******** ALB ********


# resource "aws_lb" "demo" {
#   name = "demo-mentorship-alb"

#   internal           = false
#   load_balancer_type = "application"
#   # security_groups    = [aws_security_group.web.id]
#   subnets = [aws_subnet.private.id, aws_subnet.public.id]

#   tags = merge(var.default_tags, {
#     Name = "Demo ALB"
#   })
# }

# resource "aws_lb_target_group" "tg1" {
#   name     = "demo-tg1"
#   protocol = "HTTP"

#   vpc_id = aws_vpc.demo.id
#   port   = 80

#   health_check {
#     path                = "/"
#     protocol            = "HTTP"
#     matcher             = "200"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#   }

#   tags = merge(var.default_tags, {
#     Name = "DemoTargetGroup1"
#   })
# }

# resource "aws_lb_target_group" "target_groups" {
#   count    = length(aws_instance.main)
#   name     = "demo-tg${count.index}"
#   protocol = "HTTP"

#   vpc_id = aws_vpc.demo.id
#   port   = 80

#   health_check {
#     path                = "/"
#     protocol            = "HTTP"
#     matcher             = "200"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#   }

#   stickiness {
#     enabled         = true
#     type            = "lb_cookie"
#     cookie_duration = 86400
#   }

#   tags = merge(var.default_tags, {
#     Name = "DemoTargetGroup${count.index}"
#   })
# }

# resource "aws_alb_target_group_attachment" "tg_attachments" {
#   count = length(aws_instance.main)

#   port             = 80
#   target_id        = aws_instance.main[count.index].id
#   target_group_arn = aws_lb_target_group.target_groups[count.index].arn
# }



# resource "aws_lb_listener" "http" {
#   load_balancer_arn = aws_lb.demo.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.target_groups[0].arn
#   }
# }

# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.demo.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = data.aws_acm_certificate.cert.arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.target_groups[0].arn
#   }
# }

# resource "aws_lb_listener_rule" "path_rule" {
#   listener_arn = aws_lb_listener.http.arn
#   priority     = 100

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.target_groups[1].arn
#   }

#   condition {
#     path_pattern {
#       values = ["/instance2"]
#     }
#   }
# }

# resource "aws_lb_listener" "http_redirect" {
#   load_balancer_arn = aws_lb.demo.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type = "redirect"
#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }

# resource "aws_lb_listener_rule" "path_rule_https" {
#   count        = 0
#   listener_arn = aws_lb_listener.https.arn
#   priority     = 100

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.target_groups[1].arn
#   }

#   condition {
#     path_pattern {
#       values = ["/instance2"]
#     }
#   }
# }

# EC2

resource "aws_instance" "amazon_linux" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  security_groups             = [aws_security_group.web.id]
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true

  key_name = data.aws_key_pair.primary.key_name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd

    # Burger-Themed Landing Page
    cat << 'HTML' > /var/www/html/index.html
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Burger Bliss - Amazon Linux</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
                font-family: 'Helvetica', sans-serif;
                background: linear-gradient(135deg, #00cc99, #33ccff);
                color: #333;
                line-height: 1.6;
            }
            header {
                background: rgba(255, 255, 255, 0.9);
                color: #333;
                padding: 20px;
                text-align: center;
                box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
            }
            header h1 {
                font-size: 2.5em;
                text-transform: uppercase;
                letter-spacing: 2px;
            }
            .container {
                max-width: 1200px;
                margin: 40px auto;
                padding: 20px;
                display: flex;
                flex-wrap: wrap;
                gap: 20px;
                justify-content: center;
            }
            .burger-card {
                background: white;
                border-radius: 15px;
                padding: 20px;
                width: 300px;
                box-shadow: 0 6px 20px rgba(0, 0, 0, 0.2);
                text-align: center;
                transition: transform 0.3s ease;
            }
            .burger-card:hover {
                transform: translateY(-10px);
            }
            .burger-card img {
                width: 100%;
                border-radius: 10px;
            }
            .burger-card h2 {
                font-size: 1.5em;
                margin: 10px 0;
                color: #00cc99;
            }
            .burger-card p {
                font-size: 1em;
                color: #666;
            }
            footer {
                background: rgba(255, 255, 255, 0.9);
                color: #333;
                text-align: center;
                padding: 15px;
                position: fixed;
                bottom: 0;
                width: 100%;
                font-size: 0.9em;
            }
            footer a {
                color: #33ccff;
                text-decoration: none;
            }
        </style>
    </head>
    <body>
        <header>
            <h1>Burger Bliss - Amazon Linux</h1>
        </header>
        <div class="container">
            <div class="burger-card">
                <img src="https://via.placeholder.com/280x180.png?text=Bacon+Burger" alt="Bacon Burger">
                <h2>Bacon Burger</h2>
                <p>Crispy bacon, cheddar, and smoky BBQ sauce.</p>
            </div>
            <div class="burger-card">
                <img src="https://via.placeholder.com/280x180.png?text=Mushroom+Burger" alt="Mushroom Burger">
                <h2>Mushroom Burger</h2>
                <p>Sautéed mushrooms with Swiss cheese.</p>
            </div>
            <div class="burger-card">
                <img src="https://via.placeholder.com/280x180.png?text=Double+Burger" alt="Double Burger">
                <h2>Double Burger</h2>
                <p>Two patties, double cheese, ultimate satisfaction.</p>
            </div>
        </div>
        <footer>
            <p>Developed by <a href="https://github.com/ivasik-k7" target="_blank">Ivan Kovtun</a> &copy; 2025</p>
        </footer>
    </body>
    </html>
    HTML

    # Install Node.js and WebSocket Server
    curl -sL https://rpm.nodesource.com/setup_16.x | bash -
    yum install -y nodejs
    npm install -g ws
    echo 'const WebSocket = require("ws"); const wss = new WebSocket.Server({ port: 8080 }); wss.on("connection", ws => { ws.on("message", msg => ws.send("Echo from Amazon Linux: " + msg)); });' > /home/ec2-user/server.js
    node /home/ec2-user/server.js &
    EOF

  tags = merge(var.default_tags, {
    "Name"        = "amazon-linux-alb-test-server"
    "Description" = "Amazon Linux instance with burger-themed landing page"
  })
}

resource "aws_instance" "ubuntu" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  security_groups             = [aws_security_group.web.id]
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true

  key_name = data.aws_key_pair.primary.key_name

  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install -y apache2
    systemctl start apache2
    systemctl enable apache2

    # Burger-Themed Landing Page
    cat << 'HTML' > /var/www/html/index.html
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Burger Bonanza - Ubuntu</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
                font-family: 'Arial', sans-serif;
                background: linear-gradient(135deg, #ffcc00, #ff5733);
                color: #333;
                line-height: 1.6;
            }
            header {
                background: rgba(0, 0, 0, 0.8);
                color: white;
                padding: 20px;
                text-align: center;
                box-shadow: 0 4px 10px rgba(0, 0, 0, 0.3);
            }
            header h1 {
                font-size: 2.5em;
                text-transform: uppercase;
                letter-spacing: 2px;
            }
            .container {
                max-width: 1200px;
                margin: 40px auto;
                padding: 20px;
                display: flex;
                flex-wrap: wrap;
                gap: 20px;
                justify-content: center;
            }
            .burger-card {
                background: white;
                border-radius: 15px;
                padding: 20px;
                width: 300px;
                box-shadow: 0 6px 20px rgba(0, 0, 0, 0.2);
                text-align: center;
                transition: transform 0.3s ease;
            }
            .burger-card:hover {
                transform: translateY(-10px);
            }
            .burger-card img {
                width: 100%;
                border-radius: 10px;
            }
            .burger-card h2 {
                font-size: 1.5em;
                margin: 10px 0;
                color: #ff5733;
            }
            .burger-card p {
                font-size: 1em;
                color: #666;
            }
            footer {
                background: rgba(0, 0, 0, 0.8);
                color: white;
                text-align: center;
                padding: 15px;
                position: fixed;
                bottom: 0;
                width: 100%;
                font-size: 0.9em;
            }
            footer a {
                color: #ffcc00;
                text-decoration: none;
            }
        </style>
    </head>
    <body>
        <header>
            <h1>Burger Bonanza - Ubuntu</h1>
        </header>
        <div class="container">
            <div class="burger-card">
                <img src="https://via.placeholder.com/280x180.png?text=Classic+Burger" alt="Classic Burger">
                <h2>Classic Burger</h2>
                <p>Juicy beef patty with lettuce, tomato, and secret sauce.</p>
            </div>
            <div class="burger-card">
                <img src="https://via.placeholder.com/280x180.png?text=Spicy+Burger" alt="Spicy Burger">
                <h2>Spicy Burger</h2>
                <p>Fiery patty with jalapeños and pepper jack cheese.</p>
            </div>
            <div class="burger-card">
                <img src="https://via.placeholder.com/280x180.png?text=Veggie+Burger" alt="Veggie Burger">
                <h2>Veggie Burger</h2>
                <p>Fresh veggies and quinoa patty, guilt-free delight.</p>
            </div>
        </div>
        <footer>
            <p>Developed by <a href="https://github.com/ivasik-k7" target="_blank">Ivan Kovtun</a> &copy; 2025</p>
        </footer>
    </body>
    </html>
    HTML

    # Install Node.js and WebSocket Server
    apt install -y nodejs npm
    npm install -g ws
    echo 'const WebSocket = require("ws"); const wss = new WebSocket.Server({ port: 8080 }); wss.on("connection", ws => { ws.on("message", msg => ws.send("Echo from Ubuntu: " + msg)); });' > /home/ubuntu/server.js
    node /home/ubuntu/server.js &
    EOF

  tags = merge(var.default_tags, {
    "Name"        = "ubuntu-alb-test-server"
    "Description" = "Ubuntu instance with burger-themed landing page"
  })
}
