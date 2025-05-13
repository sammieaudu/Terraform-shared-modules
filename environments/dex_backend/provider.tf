terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

# Configure the AWS Provider for the network module
provider "aws" {
  alias   = "network"
  region  = var.region
  profile = var.aws_profile
}

