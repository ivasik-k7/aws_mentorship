# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_default_security_group_id" {
  description = "The ID of the default security group created with the VPC"
  value       = aws_vpc.main.default_security_group_id
}

output "vpc_default_route_table_id" {
  description = "The ID of the default route table created with the VPC"
  value       = aws_vpc.main.default_route_table_id
}

output "vpc_owner_id" {
  description = "The AWS account ID of the VPC owner"
  value       = aws_vpc.main.owner_id
}

# Internet Gateway Outputs
output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = aws_subnet.public[*].arn
}

output "public_subnet_cidr_blocks" {
  description = "List of CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "public_subnet_availability_zones" {
  description = "List of availability zones for public subnets"
  value       = aws_subnet.public[*].availability_zone
}

output "public_subnet_map_public_ip_on_launch" {
  description = "List indicating if public subnets auto-assign public IPs"
  value       = aws_subnet.public[*].map_public_ip_on_launch
}

# Private Subnets Outputs
output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = aws_subnet.private[*].arn
}

output "private_subnet_cidr_blocks" {
  description = "List of CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "private_subnet_availability_zones" {
  description = "List of availability zones for private subnets"
  value       = aws_subnet.private[*].availability_zone
}

output "private_subnet_map_public_ip_on_launch" {
  description = "List indicating if private subnets auto-assign public IPs"
  value       = aws_subnet.private[*].map_public_ip_on_launch
}

# NAT Gateway Outputs (Conditional)
output "nat_gateway_id" {
  description = "The ID of the NAT Gateway (if enabled)"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "nat_gateway_public_ip" {
  description = "The public IP address of the NAT Gateway (if enabled)"
  value       = var.enable_nat_gateway ? aws_eip.nat[0].public_ip : null
}

output "nat_gateway_allocation_id" {
  description = "The allocation ID of the Elastic IP for the NAT Gateway (if enabled)"
  value       = var.enable_nat_gateway ? aws_eip.nat[0].id : null
}

output "nat_gateway_subnet_id" {
  description = "The subnet ID where the NAT Gateway is deployed (if enabled)"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[0].subnet_id : null
}

# Route Table Outputs
output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public.id
}

output "public_route_table_routes" {
  description = "List of routes in the public route table"
  value       = aws_route_table.public.route
}

output "private_route_table_id" {
  description = "The ID of the private route table"
  value       = aws_route_table.private.id
}

output "private_route_table_routes" {
  description = "List of routes in the private route table (includes NAT Gateway route if enabled)"
  value       = aws_route_table.private.route
}

# Route Table Association Outputs
output "public_route_table_association_ids" {
  description = "List of IDs of public route table associations"
  value       = aws_route_table_association.public[*].id
}

output "public_route_table_association_subnet_ids" {
  description = "List of subnet IDs associated with the public route table"
  value       = aws_route_table_association.public[*].subnet_id
}

output "private_route_table_association_ids" {
  description = "List of IDs of private route table associations"
  value       = aws_route_table_association.private[*].id
}

output "private_route_table_association_subnet_ids" {
  description = "List of subnet IDs associated with the private route table"
  value       = aws_route_table_association.private[*].subnet_id
}

# VPC Flow Logs Outputs (Conditional)
output "vpc_flow_log_id" {
  description = "The ID of the VPC Flow Log (if enabled)"
  value       = var.enable_flow_logs ? aws_flow_log.vpc_flow_log[0].id : null
}

output "vpc_flow_log_arn" {
  description = "The ARN of the VPC Flow Log (if enabled)"
  value       = var.enable_flow_logs ? aws_flow_log.vpc_flow_log[0].arn : null
}

output "vpc_flow_log_destination" {
  description = "The destination (e.g., S3 bucket or CloudWatch Logs) for VPC Flow Logs (if enabled)"
  value       = var.enable_flow_logs ? aws_flow_log.vpc_flow_log[0].log_destination : null
}

# Combined Outputs for Convenience
output "all_subnet_ids" {
  description = "Combined list of all subnet IDs (public and private)"
  value       = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
}

output "vpc_details" {
  description = "A map of key VPC details for quick reference"
  value = {
    id                  = aws_vpc.main.id
    cidr_block          = aws_vpc.main.cidr_block
    internet_gateway    = aws_internet_gateway.igw.id
    public_subnets      = aws_subnet.public[*].id
    private_subnets     = aws_subnet.private[*].id
    nat_gateway         = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : "disabled"
    public_route_table  = aws_route_table.public.id
    private_route_table = aws_route_table.private.id
  }
}


output "public_route_table_ids" {
  description = "List of public route table IDs"
  value       = [aws_route_table.public.id]
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = [aws_route_table.private.id]
}

output "all_subnet_availability_zones" {
  description = "List of all availability zones used across public and private subnets"
  value = distinct(concat(
    aws_subnet.public[*].availability_zone,
    aws_subnet.private[*].availability_zone
  ))
}

output "subnet_id_map" {
  description = "Map of public and private subnet IDs"
  value = {
    public  = aws_subnet.public[*].id
    private = aws_subnet.private[*].id
  }
}
