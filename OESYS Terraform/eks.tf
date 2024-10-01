module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.24.0"

  cluster_name    = var.eks_cluster_name
  cluster_version = "1.21"
  subnets         = concat(var.public_subnets, var.private_subnets)
  vpc_id          = module.vpc.vpc_id

  node_groups = {
    eks_nodes = {
      desired_capacity = 2
      max_size         = 3
      min_size         = 1
      instance_type    = var.instance_type
    }
  }

  tags = {
    Environment = "production"
  }
}
