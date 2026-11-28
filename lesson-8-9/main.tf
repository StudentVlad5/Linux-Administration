terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "lesson-8-vpc"
  cluster_name       = "lesson-8-eks"
}

module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "django-app"
  scan_on_push = true
}

module "eks" {
  source         = "./modules/eks"
  cluster_name   = "lesson-8-eks"
  subnet_ids     = module.vpc.public_subnet_ids
  instance_types = ["t3.small"]
}

module "jenkins" {
  source                 = "./modules/jenkins"
  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_ca_certificate
  jenkins_ecr_role_arn   = module.eks.jenkins_ecr_role_arn
  github_token           = var.github_token
}

module "argo_cd" {
  source                 = "./modules/argo_cd"
  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_ca_certificate
  repo_url               = "https://github.com/StudentVlad5/Linux-Administration.git"
  target_revision        = "lesson-db-module"
  chart_path             = "lesson-8-9/charts/django-app"
}
module "rds" {
  source = "./modules/rds"

  project_name = "django-app"
  environment  = "dev"
  use_aurora   = false

  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  allowed_cidr_blocks = ["10.0.0.0/16"]

  engine           = "postgres"
  engine_version   = "15"
  parameter_family = "postgres15"
  instance_class   = "db.t3.micro"
  multi_az         = false

  db_name         = "djangodb"
  master_username = "dbadmin"
  master_password = var.db_password

  db_parameters = {
    max_connections = "100"
    log_statement   = "all"
    work_mem        = "4096"
  }

  depends_on = [module.vpc]
}

module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "vlad-popov-terraform-state-us-west-2"
  table_name  = "terraform-locks"
}
