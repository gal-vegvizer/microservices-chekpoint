output "vpc_id" {
  value = module.vpc.vpc_id
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "sqs_queue_url" {
  value = module.sqs.queue_url
}

output "ecr_microservice_1_repository_url" {
  description = "The URL of the microservice-1 ECR repository"
  value       = module.ecr.microservice_1_repository_url
}

output "ecr_microservice_2_repository_url" {
  description = "The URL of the microservice-2 ECR repository"
  value       = module.ecr.microservice_2_repository_url
}

output "api_token_ssm_parameter_name" {
  description = "Name of the SSM parameter storing the API token"
  value       = var.ssm_token_name
}

output "api_token_value" {
  description = "The generated API token (sensitive - use 'terraform output -raw api_token_value' to retrieve)"
  value       = var.ssm_token_value != null ? var.ssm_token_value : random_password.api_token.result
  sensitive   = true
}
