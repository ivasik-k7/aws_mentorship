variable "region" {
  default     = "eu-central-1"
  description = "AWS region to deploy resources"
}

variable "secondary_region" {
  description = "value of the secondary region"
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  default     = "dev"
  description = "Environment to deploy resources"
}

variable "domain_name" {
  default     = "quaeb9ph.amakarov.info"
  description = "Domain name for the application"
}

variable "default_tags" {
  default = {
    owner   = "Ivan Kovtun"
    tier    = "private"
    purpose = "demo"
  }
  description = "Default tags for all resources"
}

variable "db_password" {
  description = "value of the database password"
  type        = string
  sensitive   = true
  default     = "MySecurePass123"
}

variable "db_user" {
  description = "value of the database user"
  type        = string
  sensitive   = true
  default     = "admin"
}
