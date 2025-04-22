data "aws_caller_identity" "current" {}

data "aws_key_pair" "primary" {
  key_name = "Primary"
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  owners = ["amazon"]
}

data "aws_availability_zones" "available" {
  state = "available"
}
