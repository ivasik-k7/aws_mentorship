variable "region" {
  default     = "eu-central-1"
  description = "AWS region to deploy resources"
}

variable "environment" {
  default     = "dev"
  description = "Environment to deploy resources"
}

variable "domain" {
  default     = "example.com"
  description = "Domain name"
}

variable "default_tags" {
  default = {
    owner   = "Ivan Kovtun"
    tier    = "private"
    purpose = "demo"
  }
  description = "Default tags for all resources"
}
