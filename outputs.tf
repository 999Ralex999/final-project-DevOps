output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "ecr_url" {
  description = "ECR URL"
  value       = module.ecr.repository_url
}

output "eks_cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_id
}

output "eks_endpoint" {
  description = "EKS API Endpoint"
  value       = module.eks.cluster_endpoint
}

