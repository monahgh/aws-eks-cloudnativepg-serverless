output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "kubeconfig_command" {
  description = "Command to configure kubectl for the cluster."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "rds_endpoint" {
  description = "Multi-AZ RDS PostgreSQL endpoint."
  value       = module.rds.db_instance_address
}

output "rds_secret_arn" {
  description = "Secrets Manager ARN holding the RDS master credentials."
  value       = module.rds.db_instance_master_user_secret_arn
}

output "api_url" {
  description = "HTTP API invoke URL."
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "audit_topic_arn" {
  description = "SNS topic receiving audit events."
  value       = aws_sns_topic.audit.arn
}
