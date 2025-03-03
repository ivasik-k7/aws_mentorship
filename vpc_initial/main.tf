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

# resource "aws_vpc" "peer" {
#     cidr_block = "10.1.0.0/24"

#     tags = local.default_tags

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
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/26"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = merge(var.default_tags, { Name = "public-subnet" })
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = count.index == 0 ? "10.0.0.64/26" : "10.0.0.128/26"
  availability_zone = data.aws_availability_zones.available.names[count.index + 1]
  tags              = merge(var.default_tags, { Name = "private-subnet-${count.index + 1}" })
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
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.demo_sg.id]

  tags = merge(var.default_tags, { Name = "ubuntu-instance" })
}

resource "aws_instance" "windows" {
  ami                    = data.aws_ami.windows.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private[1].id
  vpc_security_group_ids = [aws_security_group.demo_sg.id]

  tags = merge(var.default_tags, { Name = "windows-instance" })
}
