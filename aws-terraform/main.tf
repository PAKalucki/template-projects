terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.74.3"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
     Environment = var.env
     Terraform   = "True"
    }
  }
}

data "aws_caller_identity" "current" {}