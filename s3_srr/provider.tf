terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.primary_region
}

provider "aws" {
  alias  = "alternate"
  region = var.alternate_region
}
