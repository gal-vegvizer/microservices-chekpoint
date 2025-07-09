output "microservice_1_repository_url" {
  description = "The URL of the microservice-1 ECR repository"
  value       = aws_ecr_repository.microservice_1.repository_url
}

output "microservice_2_repository_url" {
  description = "The URL of the microservice-2 ECR repository"
  value       = aws_ecr_repository.microservice_2.repository_url
}
