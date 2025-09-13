terraform {
  required_version = ">= 1.13.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.29.0"
    }
  }
}

provider "aws" {
  region = var.region
}
