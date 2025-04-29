variable "region" {
  default     = "eu-central-1"
  description = "AWS region to deploy resources"
}

variable "google_client_id" {
  default     = "your-google-client-id"
  description = "Google client ID for Cognito"
}

variable "google_client_secret" {
  default     = "your-google-client-secret"
  description = "Google client secret for Cognito"
}

variable "facebook_client_id" {
  default     = "your-facebook-client-id"
  description = "Facebook client ID for Cognito"
}

variable "facebook_client_secret" {
  default     = "your-facebook-client-secret"
  description = "Facebook client secret for Cognito"
}

variable "apple_client_id" {
  default     = "your-apple-client-id"
  description = "Apple client ID for Cognito"
}

variable "apple_team_id" {
  default     = "your-apple-team-id"
  description = "Apple team ID for Cognito"
}

variable "apple_key_id" {
  default     = "your-apple-key-id"
  description = "Apple key ID for Cognito"
}

variable "apple_private_key" {
  default     = "your-apple-private-key"
  description = "Apple private key for Cognito"
}

variable "environment" {
  default     = "dev"
  description = "Environment to deploy resources"
}

variable "default_tags" {
  default = {
    Owner   = "Ivan Kovtun"
    Tier    = "private"
    Purpose = "demo"
  }
  description = "Default tags for all resources"
}
