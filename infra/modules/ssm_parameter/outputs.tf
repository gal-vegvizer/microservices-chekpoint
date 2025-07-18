output "arn" {
  value = aws_ssm_parameter.this.arn
}

output "name" {
  value = aws_ssm_parameter.this.name
}

output "value" {
  value     = aws_ssm_parameter.this.value
  sensitive = true
}
