output "cluster_name" {
  description = "Name of the ECS cluster hosting the payment API."
  value       = aws_ecs_cluster.payments.name
}

output "staging_service_name" {
  description = "Name of the staging payment API service."
  value       = aws_ecs_service.payment_api_staging.name
}

output "prod_service_name" {
  description = "Name of the production payment API service."
  value       = aws_ecs_service.payment_api_prod.name
}

output "state_bucket" {
  description = "S3 bucket used for Terraform remote state."
  value       = aws_s3_bucket.tf_state.bucket
}
