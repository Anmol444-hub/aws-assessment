terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = "us-east-1"
}

module "labels" {
  source = "../../modules/aws-terraform-labels"

  name        = var.name
  environment = var.environment
  region      = "us-east-1"
  project     = var.project
  tags        = var.tags
}

module "cognito" {
  source = "../../modules/aws-terraform-cognito"

  labels             = module.labels
  user_email         = var.user_email
  user_temp_password = var.user_temp_password
}
