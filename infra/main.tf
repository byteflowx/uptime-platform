terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.73"
    }
  }

  backend "s3" {
    key          = "uptime-platform/terraform.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-north-1"

  default_tags {
    tags = { Project = "uptime-platform" }
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.7"

  name             = "uptime"
  cidr             = "10.0.0.0/16"
  azs              = ["eu-north-1a", "eu-north-1b"]
  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]
  database_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
}
