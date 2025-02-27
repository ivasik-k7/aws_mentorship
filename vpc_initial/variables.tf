variable "region" {
  default     = "eu-central-1"
  description = "AWS region to deploy resources"
}

variable "vpc_cidr" {
  default     = "10.0.0.0/24"
  description = "CIDR block for the main VPC"
}

variable "default_tags" {
  default = {
    owner   = "Ivan Kovtun"
    tier    = "private"
    purpose = "demo"
  }
  description = "Default tags for all resources"
}