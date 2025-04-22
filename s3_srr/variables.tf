variable "primary_region" {
  default     = "eu-central-1"
  description = "AWS region to deploy resources"
}

variable "alternate_region" {
  default     = "us-east-1"
  description = "AWS region to deploy resources"

}

variable "environment" {
  default     = "dev"
  description = "Environment to deploy resources"
}

variable "domain" {
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
