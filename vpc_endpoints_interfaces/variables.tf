variable "region" {
  default     = "eu-central-1"
  description = "AWS region to deploy resources"
}

variable "is_create_sns" {
  default     = false
  description = ""
  type        = bool
}

variable "sns_topic_name" {
  default     = "test-topic"
  type        = string
  description = "SNS topic name"
}

variable "is_create_sqs" {
  default     = false
  description = ""
  type        = bool
}

variable "sqs_queue_name" {
  type        = string
  description = "SQS queue name"
  default     = "test-queue"
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

# variable "route_table_ids" {
#   description = "List of route table IDs for Gateway Endpoints"
#   type        = list(string)
#   default     = []
# }

# variable "subnet_ids" {
#   description = "List of subnet IDs for Interface Endpoints"
#   type        = list(string)
#   default     = []
# }

# variable "security_group_ids" {
#   description = "List of security group IDs for Interface Endpoints"
#   type        = list(string)
#   default     = []
# }
