resource "aws_ecr_repository" "microservice_1" {
  name = "${var.project_name}/microservice-1"
  
  tags = {
    Name = "${var.project_name}-microservice-1"
  }
}

resource "aws_ecr_repository" "microservice_2" {
  name = "${var.project_name}/microservice-2"
  
  tags = {
    Name = "${var.project_name}-microservice-2"
  }
}
