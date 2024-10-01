provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./vpc.tf"
}

module "eks" {
  source = "./eks.tf"
}

module "alb" {
  source = "./alb.tf"
}

# Outputs
output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "alb_dns" {
  value = aws_lb.app_lb.dns_name
}
