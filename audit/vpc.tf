module "vpc" {
  source = "../modules/vpc"

  identifier = "audit-vpc-${var.environment}"

  availability_zones = data.aws_availability_zones.available.names

  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_flow_logs   = false
  enable_nat_gateway = false

  default_tags = merge(var.default_tags, {
    Name = "audit-vpc-${var.environment}"
  })
}


