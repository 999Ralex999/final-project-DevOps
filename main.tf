terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "kubernetes" {
  alias       = "eks"
  config_path = "~/.kube/config"
}

provider "aws" {
  region = "us-west-2"
}

provider "helm" {
  alias = "eks"

  kubernetes = {
    config_path = "~/.kube/config"
  }
}

module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "lesson-7-terraform-state"
  table_name  = "lesson-7-locks"
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "lesson-7-vpc"
}

module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-7-ecr"
  scan_on_push = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"

  cluster_name    = "lesson-7-cluster"
  cluster_version = "1.29"
  subnet_ids      = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id

  enable_irsa = true

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  create_cloudwatch_log_group  = false
  create_aws_auth_configmap = false


  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::655307635386:user/terraform"
      username = "terraform"
      groups   = ["system:masters"]
    }
  ]

  eks_managed_node_groups = {
    default = {
      desired_size   = 2
      max_size       = 3
      min_size       = 1
      instance_types = ["t3.small"]
      capacity_type  = "ON_DEMAND"
    }
  }

  tags = {
    Environment = "dev"
    Project     = "lesson-7"
  }
}


#module "jenkins" {
#  source       = "./modules/jenkins"
#  kubeconfig   = "~/.kube/config"
#  cluster_name = "lesson-7-cluster"
#}

#module "argocd" {
#  source = "./modules/argocd"

#  cluster_name = var.cluster_name
#  kubeconfig   = var.kubeconfig
#}

module "jenkins" {
  source       = "./modules/jenkins"
  cluster_name = module.eks.cluster_name
  kubeconfig   = var.kubeconfig

  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }
}

module "argocd" {
  source       = "./modules/argocd"
  cluster_name = module.eks.cluster_name
  kubeconfig   = var.kubeconfig

  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }
}

module "rds" {
  source = "./modules/rds"

  name                       = "myapp-db"
  use_aurora                 = false
  aurora_instance_count      = 2

  # --- Aurora ---
  engine_cluster             = "aurora-postgresql"
  engine_version_cluster     = "15.3"
  parameter_group_family_aurora = "aurora-postgresql15"

  # --- RDS ---
  engine                     = "postgres"
  engine_version             = "17.2"
  parameter_group_family_rds = "postgres17"

  # --- Общие ---
  instance_class             = "db.t3.micro"
  allocated_storage          = 20
  db_name                    = "myapp"
  username                   = "postgres"
  password                   = "admin123AWS23"

  subnet_private_ids         = module.vpc.private_subnets
  subnet_public_ids          = module.vpc.public_subnets
  publicly_accessible        = true
  vpc_id                     = module.vpc.vpc_id
  multi_az                   = true
  backup_retention_period    = 7

  parameters = {
    max_connections            = "200"
    log_min_duration_statement = "500"
  }

  tags = {
    Environment = "dev"
    Project     = "myapp"
  }
}
