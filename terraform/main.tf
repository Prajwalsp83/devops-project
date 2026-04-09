provider "aws" {
  region = "ap-south-1"
}

# -----------------------
# VPC
# -----------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "devops-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-south-1a", "ap-south-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Name = "devops-vpc"
  }
}

# -----------------------
# EKS
# -----------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "devops-cluster"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # 🔥 IMPORTANT FIXES
  enable_irsa                     = true
  create_cloudwatch_log_group     = false
  cluster_endpoint_public_access  = true

  # 🔐 ACCESS FIX (ROOT USER)
  access_entries = {
    root = {
      principal_arn = "arn:aws:iam::848104065212:root"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # 💰 LOW COST NODE GROUP
  eks_managed_node_groups = {
    default = {
      desired_size = 1
      max_size     = 1
      min_size     = 1

      instance_types = ["t3.small"]
      ami_type       = "AL2_x86_64"
    }
  }

  tags = {
    Name = "devops-eks"
  }
}
