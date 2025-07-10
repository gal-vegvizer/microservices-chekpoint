variable "project_name" {
  description = "Project name prefix for resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the security group."
  type        = string
}

variable "ingress_port" {
  description = "Port to allow inbound traffic."
  type        = number
}

variable "alb_security_group_id" {
  description = "The ALB security group ID to allow traffic from"
  type        = string
  default     = null
}
