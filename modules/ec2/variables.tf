variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "subnet_ids" {
  description = "List of subnet IDs for instance placement"
  type        = list(string)
}

variable "associate_public_ip" {
  description = "Whether to associate a public IP"
  type        = bool
  default     = true
}

variable "user_data" {
  description = "User data script for instance initialization"
  type        = string
  default     = ""
}

variable "ebs_volume_size" {
  description = "Size of the EBS volume in GB"
  type        = number
  default     = 8
}

variable "ebs_volume_type" {
  description = "Type of EBS volume (e.g., gp3, gp2)"
  type        = string
  default     = "gp3"
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "instance_tags" {
  description = "Additional tags for EC2 instances"
  type        = map(string)
  default     = {}
}

variable "enable_autoscaling" {
  description = "Enable Auto Scaling Group"
  type        = bool
  default     = false
}

variable "instance_count" {
  description = "Number of instances if Auto Scaling is disabled"
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 1
}

variable "target_group_arns" {
  description = "List of ALB target group ARNs for ASG"
  type        = list(string)
  default     = []
}

variable "health_check_type" {
  description = "Health check type for ASG (EC2 or ELB)"
  type        = string
  default     = "EC2"
}

variable "iam_role_name" {
  description = "Name of IAM role to attach to instances (optional)"
  type        = string
  default     = ""
}
