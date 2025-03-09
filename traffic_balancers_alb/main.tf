data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "demo" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.default_tags, {
    Name = "Demo VPC"
  })
}

data "aws_key_pair" "primary" {
  key_name = "Primary"
}

# data "aws_acm_certificate" "cert" {
#   domain   = "mentorship-test.com"
#   statuses = ["ISSUED"]
# }

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
    Name = "Demo Private Subnet"
  })
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.demo.id

  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]


  tags = merge(var.default_tags, {
    Name = "Demo Public Subnet"
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.demo.id

  tags = merge(var.default_tags, {
    Name = "Demo Private Route Table"
  })
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.default_tags, {
    Name = "Demo Public Route Table"
  })
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


# alb

resource "aws_lb" "demo" {
  name = "demo-mentorship-alb"

  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = [aws_subnet.private.id, aws_subnet.public.id]

  tags = merge(var.default_tags, {
    Name = "Demo ALB"
  })
}

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

resource "aws_lb_target_group" "target_groups" {
  count    = length(aws_instance.main)
  name     = "demo-tg${count.index}"
  protocol = "HTTP"

  vpc_id = aws_vpc.demo.id
  port   = 80

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  stickiness {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 86400
  }

  tags = merge(var.default_tags, {
    Name = "DemoTargetGroup${count.index}"
  })
}

resource "aws_alb_target_group_attachment" "tg_attachments" {
  count = length(aws_instance.main)

  port             = 80
  target_id        = aws_instance.main[count.index].id
  target_group_arn = aws_lb_target_group.target_groups[count.index].arn
}



resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.demo.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_groups[0].arn
  }
}

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

resource "aws_lb_listener_rule" "path_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_groups[1].arn
  }

  condition {
    path_pattern {
      values = ["/instance2"]
    }
  }
}

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

resource "aws_security_group" "web" {
  vpc_id = aws_vpc.demo.id

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
    Name = "PublicAccessSG"
  })
}

resource "aws_instance" "main" {
  count                       = 2
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.web.id]

  key_name = data.aws_key_pair.primary.key_name

  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install -y apache2
    systemctl start apache2
    systemctl enable apache2
    echo "Hello from instance ${count.index}" > /var/www/html/index.html

    apt install -y nodejs npm
    npm install -g ws
    echo 'const WebSocket = require("ws"); const wss = new WebSocket.Server({ port: 8080 }); wss.on("connection", ws => { ws.on("message", msg => ws.send("Echo: " + msg)); });' > /home/ubuntu/server.js
    node /home/ubuntu/server.js &
    EOF

  tags = merge(var.default_tags, {
    "Name"        = "${count.index}-alb-test-ubuntu-server"
    "Description" = "Main instance"
  })
}
