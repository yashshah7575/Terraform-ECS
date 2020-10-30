provider "aws" {
  region     = var.region
  version    = "~> 2.0"
}

module "vpc" {
  source             = "./vpc"
  name               = var.name
  cidr               = var.cidr
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
  environment        = var.environment
}

#availability_zones = var.availability_zones