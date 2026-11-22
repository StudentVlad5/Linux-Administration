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
}

module "argo_cd" {
  source                 = "./modules/argo_cd"
  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_ca_certificate
  repo_url               = "https://github.com/StudentVlad5/Linux-Administration.git"
  target_revision        = "lesson-8-9"
  chart_path             = "lesson-8-9/charts/django-app"
}