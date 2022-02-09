terraform {
  backend "s3" {
    profile        = "ipfs"
    region         = "us-west-2"
    bucket         = "management-ipfs-elastic-provider"
    dynamodb_table = "management-ipfs-elastic-provider-lock"
    key            = "management-ipfs-elastic-provider.tfstate"
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.38"
    }

    helm = { # Required for cert manager
      source  = "hashicorp/helm"
      version = "~> 2.4.1"
    }
  }

  required_version = ">= 1.0.0"
}


data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_id
}

provider "aws" {
  profile = var.profile
  region  = var.region
  default_tags {
    tags = {
      Team        = "NearForm"
      Project     = "AWS-IPFS"
      Environment = "POC"
      Subsystem   = "Management"
      ManagedBy   = "Terraform"
    }
  }
}

data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name                 = var.vpc.name
  cidr                 = "10.10.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.10.1.0/24", "10.10.2.0/24"] # Worker Nodes
  public_subnets       = ["10.10.5.0/24", "10.10.6.0/24"] # and NAT
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

module "eks" {
  source                             = "terraform-aws-modules/eks/aws"
  version                            = "~> 18.2.0"
  cluster_name                       = var.cluster_name
  cluster_version                    = var.cluster_version
  cluster_endpoint_private_access    = true
  cluster_endpoint_public_access     = true
  vpc_id                             = module.vpc.vpc_id
  subnet_ids                         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
  enable_irsa                        = true # To be able to access AWS services from PODs  
  cluster_security_group_description = "EKS cluster security group - Control Plane"

  cluster_endpoint_public_access_cidrs = [
    "${chomp(data.http.myip.body)}/32", 
  ]

  eks_managed_node_groups = { # Needed for CoreDNS (https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html)
    test-ipfs-peer-subsys = {
      name         = "test-ipfs-peer-subsys"
      desired_size = 2
      min_size     = 1
      max_size     = 4

      instance_types = ["t3.large"]
      k8s_labels = {
        workerType = "managed_ec2_node_groups"
      }
      update_config = {
        max_unavailable_percentage = 50
      }

      tags = { # This is also applied to IAM role.
        "eks/${var.accountId}/${var.cluster_name}/type" : "node"
      }
    }
  }

  node_security_group_additional_rules = local.node_security_group_additional_rules
}
