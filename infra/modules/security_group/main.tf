resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "Allow inbound traffic for ECS service"
  vpc_id      = var.vpc_id

  # Allow traffic from ALB security group if provided, otherwise allow from anywhere
  dynamic "ingress" {
    for_each = var.alb_security_group_id != null ? [1] : []
    content {
      description     = "Allow ALB to talk to ECS"
      from_port       = var.ingress_port
      to_port         = var.ingress_port
      protocol        = "tcp"
      security_groups = [var.alb_security_group_id]
    }
  }

  # Fallback rule for non-ALB services (like SQS worker)
  dynamic "ingress" {
    for_each = var.alb_security_group_id == null ? [1] : []
    content {
      from_port   = var.ingress_port
      to_port     = var.ingress_port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}

output "ecs_sg_id" {
  value = aws_security_group.ecs.id
}
