terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# Підключаємо модуль S3 та DynamoDB
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "vladyslav-popov-tf-state-lesson5"
  table_name  = "terraform-locks"
}

# Підключаємо модуль VPC
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "lesson-7-vpc"
  cluster_name       = "lesson-7-eks"
}

# Підключаємо модуль ECR (залишаємо тільки один блок!)
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "django-app" # Якщо у modules/ecr/variables.tf змінна називається repository_name — замініть ecr_name на repository_name
  scan_on_push = true         # Видаліть цей рядок, якщо у modules/ecr/variables.tf немає змінної scan_on_push
}

# Підключаємо модуль EKS
module "eks" {
  source       = "./modules/eks"
  cluster_name = "lesson-7-eks"
  subnet_ids   = module.vpc.public_subnet_ids
}