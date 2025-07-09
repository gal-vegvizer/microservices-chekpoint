resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-ecs-cluster"
}

output "cluster_id" {
  value = aws_ecs_cluster.main.id
}
