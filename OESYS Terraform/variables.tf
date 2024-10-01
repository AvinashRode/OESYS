variable "region" {
  description = "AWS region to deploy resources"
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "172.16.0.0/16"
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  default     = ["172.16.10.0/24", "172.16.20.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  default     = ["172.16.1.0/24", "172.16.2.0/24"]
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  default     = "my-eks-cluster"
}

variable "instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  default     = "t3.medium"
}

variable "alb_name" {
  description = "Name of the Application Load Balancer"
  default     = "app-alb"
}
