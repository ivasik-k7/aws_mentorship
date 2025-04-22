module "vpc_de" {
  source = "../modules/vpc"

  availability_zones = data.aws_availability_zones.primary.names
  identifier         = "${var.environment}-vpc-${data.aws_caller_identity.current.account_id}"


  vpc_cidr             = "10.1.0.0/16"
  public_subnet_cidrs  = ["10.1.2.0/24", "10.1.3.0/24"]
  private_subnet_cidrs = ["10.1.4.0/24", "10.1.5.0/24"]

  enable_nat_gateway = false
  enable_flow_logs   = false

  default_tags = var.default_tags
}

module "vpc_uk" {
  source = "../modules/vpc"
  providers = {
    aws = aws.secondary
  }

  identifier         = "${var.environment}-vpc-uk-${data.aws_caller_identity.current.account_id}"
  availability_zones = data.aws_availability_zones.secondary.names

  vpc_cidr             = "10.2.0.0/16"
  public_subnet_cidrs  = ["10.2.1.0/24"]
  private_subnet_cidrs = ["10.2.2.0/24"]

  enable_nat_gateway = false
  enable_flow_logs   = false

  default_tags = var.default_tags
}

resource "aws_vpc_peering_connection" "cross_region" {
  depends_on = [module.vpc_de, module.vpc_uk]

  provider    = aws
  vpc_id      = module.vpc_de.vpc_id
  peer_vpc_id = module.vpc_uk.vpc_id
  peer_region = var.secondary_region
  auto_accept = false

  tags = merge(var.default_tags, {
    Name = "${var.environment}-vpc-peering-${data.aws_caller_identity.current.account_id}"
  })
}

resource "aws_vpc_peering_connection_accepter" "accepter" {
  provider                  = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.cross_region.id
  auto_accept               = true

  tags = merge(var.default_tags, {
    Name = "${var.environment}-vpc-peering-uk-${data.aws_caller_identity.current.account_id}"
  })
}

# resource "aws_route" "de_to_uk" {
#   provider                  = aws
#   count                     = length(module.vpc_de.public_subnet_route_table_ids)  # Assuming public route tables
#   route_table_id            = module.vpc_de.public_subnet_route_table_ids[count.index]
#   destination_cidr_block    = module.vpc_uk.vpc_cidr  # e.g., 10.1.0.0/16
#   vpc_peering_connection_id = aws_vpc_peering_connection.de_to_uk.id

#   depends_on = [aws_vpc_peering_connection_accepter.uk_accept]
# }

# # Update route tables in vpc_uk to route traffic to vpc_de
# resource "aws_route" "uk_to_de" {
#   provider                  = aws.secondary
#   count                     = length(module.vpc_uk.public_subnet_route_table_ids)  # Assuming public route tables
#   route_table_id            = module.vpc_uk.public_subnet_route_table_ids[count.index]
#   destination_cidr_block    = module.vpc_de.vpc_cidr  # e.g., 10.0.0.0/16
#   vpc_peering_connection_id = aws_vpc_peering_connection.de_to_uk.id

#   depends_on = [aws_vpc_peering_connection_accepter.uk_accept]
# }
