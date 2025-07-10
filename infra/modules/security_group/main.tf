resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "Allow inbound traffic for ECS service"
  vpc_id      = var.vpc_id

  # Always allow from ALB security group if provided
  ingress {
    description     = var.alb_security_group_id != null ? "Allow ALB to talk to ECS" : "Allow traffic to ECS"
    from_port       = var.ingress_port
    to_port         = var.ingress_port
    protocol        = "tcp"
    security_groups = var.alb_security_group_id != null ? [var.alb_security_group_id] : []
    cidr_blocks     = var.alb_security_group_id == null ? ["0.0.0.0/0"] : []
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
