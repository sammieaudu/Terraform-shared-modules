output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets_ids" {
  description = "List of private subnet IDs for application workloads (e.g., EKS)"
  value       = module.vpc.private_subnets
}

output "database_subnet_ids" {
  description = "List of isolated subnet IDs for resources like RDS"
  value       = module.vpc.database_subnets
}
