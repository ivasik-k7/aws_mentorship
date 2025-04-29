variable "region" {
  default     = "eu-central-1"
  description = "AWS region to deploy resources"
}

variable "environment" {
  default     = "dev"
  description = "Environment to deploy resources"
}

variable "domain_name" {
  default     = "quaeb9Ph.amakarov.info"
  description = "Domain name for the application"
}

variable "default_tags" {
  default = {
    Owner   = "Ivan Kovtun"
    Tier    = "private"
    Purpose = "demo"
  }
  description = "Default tags for all resources"
}
