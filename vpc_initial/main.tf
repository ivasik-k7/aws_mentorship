locals {
  default_tags = {
    owner   = "Ivan Kovtun"
    tier    = "private"
    purpose = "demo"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_key_pair" "primary" {
  key_name = "Primary"
}

# Vpc part

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.default_tags, { Name = "main-vpc" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.default_tags, { Name = "main-igw" })
}



# peering part

# resource "aws_vpc" "peering" {
#   count = 0

#   tags = merge(var.default_tags, {
#     Name = "Peering Private Network"
#   })
# }

# resource "aws_vpc_peering_connection" "peer" {
#     vpc_id = aws_vpc.main.id
#     peer_vpc_id = aws_vpc.peer.id
#     auto_accept = true

#     tags = local.default_tags
# }

# resource "aws_route" "route_to_peer_vpc" {
#   route_table_id         = aws_vpc.main.main_route_table_id
#   destination_cidr_block = aws_vpc.peer_vpc.cidr_block
#   vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
# }

# resource "aws_route" "route_to_main_vpc" {
#   route_table_id         = aws_vpc.peer_vpc.main_route_table_id
#   destination_cidr_block = aws_vpc.main.cidr_block
#   vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
# }

# subnets Part

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id

  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]


  tags = merge(var.default_tags, {
    Name = "Public Subnet"
  })
}

resource "aws_subnet" "private" {
  count = 2

  vpc_id = aws_vpc.main.id

  cidr_block              = count.index == 0 ? "10.0.2.0/24" : "10.0.3.0/24"
  map_public_ip_on_launch = false

  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(var.default_tags, {
    Name = "Private Subnet ${count.index + 1}"
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  count = length(aws_subnet.private)

  tags = merge(var.default_tags, {
    Name = "Demo Private Route Table"
  })
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.default_tags, {
    Name = "Public Route Table"
  })
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


resource "aws_network_acl" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.default_tags, { Name = "main-acl" })
}

resource "aws_network_acl_rule" "ftp_in" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/24"
  from_port      = 21
  to_port        = 21
}

resource "aws_network_acl_rule" "ssh_in" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 130
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/24"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "icmp_in" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 110
  egress         = false
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/24"
  icmp_type      = -1
  icmp_code      = -1
}

resource "aws_network_acl_rule" "http_in" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/24"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "outbound" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 100
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_association" "public" {
  network_acl_id = aws_network_acl.main.id
  subnet_id      = aws_subnet.public.id
}

resource "aws_network_acl_association" "private" {
  count          = 2
  network_acl_id = aws_network_acl.main.id
  subnet_id      = aws_subnet.private[count.index].id
}

# Ec2 part

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

data "aws_ami" "windows" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["801119661308"]
}

resource "aws_security_group" "demo_sg" {
  name        = "demo-mentorship-sg"
  description = "Security group for demo mentorship"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "allow ICMP pinging"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
    description = "allow SSH"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
    description = "allow HTTP"
  }

  ingress {
    from_port   = 21
    to_port     = 21
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
    description = "allow FTP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow all outbound traffic"
  }

  tags = merge(var.default_tags, { Name = "demo-sg" })
}

resource "aws_instance" "ubuntu" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.demo_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y apache2
              cat << 'HTML' > /var/www/html/index.html
              <!DOCTYPE html>
              <html lang="en">
              <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <title>Ubuntu Landing Page</title>
                  <style>
                      body { font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f4f4f4; color: #333; }
                      header { background-color: #007BFF; color: white; padding: 20px; text-align: center; }
                      .container { max-width: 800px; margin: 50px auto; text-align: center; }
                      .cta-button { display: inline-block; padding: 15px 30px; background-color: #28A745; color: white; text-decoration: none; border-radius: 5px; font-size: 18px; }
                      .cta-button:hover { background-color: #218838; }
                      footer { background-color: #333; color: white; text-align: center; padding: 10px; position: fixed; bottom: 0; width: 100%; }
                  </style>
              </head>
              <body>
                  <header>
                      <h1>Welcome to the Ubuntu Server</h1>
                      <p>Your Cloud Journey Starts Here</p>
                  </header>
                  <div class="container">
                      <h2>Explore the Possibilities</h2>
                      <p>This is a demo landing page running on an AWS Ubuntu instance. Click below to take action!</p>
                      <a href="#" class="cta-button" onclick="alert('Button clicked!'); return false;">Get Started</a>
                  </div>
                  <footer>
                      <p>&copy; 2025 xAI Demo. All rights reserved.</p>
                  </footer>
              </body>
              </html>
              HTML
              systemctl enable apache2
              systemctl start apache2
              EOF

  tags = merge(var.default_tags, { Name = "ubuntu-instance" })
}

resource "aws_instance" "windows" {
  ami           = data.aws_ami.windows.id
  instance_type = "t2.micro"

  associate_public_ip_address = true
  key_name                    = data.aws_key_pair.primary.key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.demo_sg.id]

  user_data = <<-EOF
              <powershell>
              # Install IIS
              Install-WindowsFeature -name Web-Server -IncludeManagementTools
              
              # Create the advanced HTML landing page
              $htmlContent = @"
              <!DOCTYPE html>
              <html lang="en">
              <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <title>Windows Landing Page</title>
                  <style>
                      body { font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f4f4f4; color: #333; }
                      header { background-color: #007BFF; color: white; padding: 20px; text-align: center; }
                      .container { max-width: 800px; margin: 50px auto; text-align: center; }
                      .cta-button { display: inline-block; padding: 15px 30px; background-color: #28A745; color: white; text-decoration: none; border-radius: 5px; font-size: 18px; }
                      .cta-button:hover { background-color: #218838; }
                      footer { background-color: #333; color: white; text-align: center; padding: 10px; position: fixed; bottom: 0; width: 100%; }
                  </style>
              </head>
              <body>
                  <header>
                      <h1>Welcome to the Windows Server</h1>
                      <p>Experience the Power of AWS</p>
                  </header>
                  <div class="container">
                      <h2>Start Your Journey</h2>
                      <p>This is a demo landing page running on an AWS Windows instance. Click below to begin!</p>
                      <a href="#" class="cta-button" onclick="alert('Action triggered!'); return false;">Join Now</a>
                  </div>
                  <footer>
                      <p>&copy; 2025 xAI Demo. All rights reserved.</p>
                  </footer>
              </body>
              </html>
              "@
              Set-Content -Path "C:\inetpub\wwwroot\index.html" -Value $htmlContent
              
              # Ensure IIS is running
              Start-Service -Name W3SVC
              </powershell>
              EOF

  tags = merge(var.default_tags, { Name = "windows-instance" })
}
