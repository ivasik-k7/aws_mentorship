output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = var.enable_autoscaling ? aws_autoscaling_group.ec2[0].id : aws_instance.ec2[*].id
}

output "public_ips" {
  description = "List of public IPs (if assigned)"
  value       = var.enable_autoscaling ? [] : aws_instance.ec2[*].public_ip
}

output "private_ips" {
  description = "List of private IPs"
  value       = var.enable_autoscaling ? [] : aws_instance.ec2[*].private_ip
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = var.iam_role_name != "" ? aws_launch_template.ec2_with_iam[0].id : aws_launch_template.ec2.id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group (if enabled)"
  value       = var.enable_autoscaling ? aws_autoscaling_group.ec2[0].name : null
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile (if created)"
  value       = var.iam_role_name != "" ? aws_iam_instance_profile.ec2[0].name : null
}
