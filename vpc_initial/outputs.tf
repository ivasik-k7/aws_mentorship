output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID of the main VPC"
}

output "subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "List of subnet IDs"
}

output "ubuntu_instance_id" {
  value       = aws_instance.ubuntu.id
  description = "ID of the Ubuntu instance"
}

output "windows_instance_id" {
  value       = aws_instance.windows.id
  description = "ID of the Windows instance"
}