terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "task2-store-tfstate"
    key            = "level1/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tfstate"
  }
}
