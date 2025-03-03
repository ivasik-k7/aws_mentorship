variable "region" {
  default     = "eu-central-1"
  description = "AWS region to deploy resources"
}


variable "is_s3_create" {
  default     = false
  description = "Create S3 bucket"
  type        = bool
}

variable "bucket_name" {
  default     = ""
  description = "S3 bucket name"
}

variable "is_dynamo_create" {
  default     = false
  description = "Create DynamoDB"
  type        = bool
}

variable "dynamo_table_name" {
  default     = ""
  description = "DynamoDB table name"
}

variable "default_tags" {
  default = {
    owner   = "Ivan Kovtun"
    tier    = "private"
    purpose = "demo"
  }
  description = "Default tags for all resources"
}

variable "vpc_id" {
  description = "The ID of the VPC where endpoints will be created"
  type        = string
}

variable "route_table_ids" {
  description = "List of route table IDs for Gateway Endpoints"
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "List of subnet IDs for Interface Endpoints"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of security group IDs for Interface Endpoints"
  type        = list(string)
  default     = []
}
