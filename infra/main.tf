terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-bucket-dev2"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "microdemo-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ssm_parameter" "api_receiver_image" {
  name = "/microdemo/images/api-receiver"
}

data "aws_ssm_parameter" "sqs_worker_image" {
  name = "/microdemo/images/sqs-worker"
}

locals {
  api_receiver_image_final = var.api_receiver_image != "" ? var.api_receiver_image : data.aws_ssm_parameter.api_receiver_image.value
  sqs_worker_image_final   = var.sqs_worker_image != "" ? var.sqs_worker_image : data.aws_ssm_parameter.sqs_worker_image.value
}

module "vpc" {
  source              = "./modules/vpc"
  project_name        = var.project_name
  aws_region          = var.aws_region
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
}

module "s3" {
  source         = "./modules/s3"
  project_name   = var.project_name
  s3_bucket_name = var.s3_bucket_name
}

module "sqs" {
  source         = "./modules/sqs"
  project_name   = var.project_name
  sqs_queue_name = var.sqs_queue_name
}

module "ssm_parameter" {
  source       = "./modules/ssm_parameter"
  name         = var.ssm_token_name
  value        = var.ssm_token_value
  project_name = var.project_name
}

# Initialize SSM parameters for image URIs (will be updated by CI/CD)
resource "aws_ssm_parameter" "api_receiver_image" {
  name  = "/microdemo/images/api-receiver"
  type  = "String"
  value = "139176429165.dkr.ecr.us-east-2.amazonaws.com/microdemo/microservice-1:latest"
  overwrite = true

  # lifecycle {
  #   ignore_changes = [value] # Don't revert CI/CD updates
  # }
}

resource "aws_ssm_parameter" "sqs_worker_image" {
  name  = "/microdemo/images/sqs-worker"
  type  = "String"
  value = "139176429165.dkr.ecr.us-east-2.amazonaws.com/microdemo/microservice-2:latest"
  overwrite = true

  # lifecycle {
  #   ignore_changes = [value] # Don't revert CI/CD updates
  # }
}

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
}

module "iam" {
  source        = "./modules/iam"
  project_name  = var.project_name
  s3_bucket_arn = module.s3.bucket_arn
  sqs_queue_arn = module.sqs.queue_arn
  ssm_param_arn = module.ssm_parameter.arn
}

module "ecs_cluster" {
  source       = "./modules/ecs_cluster"
  project_name = var.project_name
}

module "ecs_api_receiver" {
  source            = "./modules/ecs"
  project_name      = var.project_name
  ecs_cluster_id    = module.ecs_cluster.cluster_id
  subnet_id         = module.vpc.public_subnet_ids[0]
  ecs_task_role_arn = module.iam.ecs_task_role_arn
  container_image   = local.api_receiver_image_final
  container_port    = var.api_receiver_port
  security_group_id = module.ecs_api_receiver_sg.ecs_sg_id
  target_group_arn  = module.alb.target_group_arn
  environment_variables = [
    { name = "AWS_REGION", value = var.aws_region },
    { name = "SQS_QUEUE_URL", value = module.sqs.queue_url },
    { name = "TOKEN_SECRET", value = module.ssm_parameter.value }
  ]
}

module "ecs_sqs_worker" {
  source            = "./modules/ecs"
  project_name      = "${var.project_name}-worker"
  ecs_cluster_id    = module.ecs_cluster.cluster_id
  subnet_id         = module.vpc.public_subnet_ids[1]
  ecs_task_role_arn = module.iam.ecs_task_role_arn
  container_image   = local.sqs_worker_image_final
  container_port    = var.sqs_worker_port
  security_group_id = module.ecs_sqs_worker_sg.ecs_sg_id
  environment_variables = [
    { name = "AWS_REGION", value = var.aws_region },
    { name = "SQS_QUEUE_URL", value = module.sqs.queue_url },
    { name = "S3_BUCKET_NAME", value = module.s3.bucket_name },
    { name = "TOKEN_SECRET", value = module.ssm_parameter.value }
  ]
}


module "alb" {
  source       = "./modules/alb"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.public_subnet_ids
  target_port  = var.api_receiver_port
}

module "ecs_api_receiver_sg" {
  source                = "./modules/security_group"
  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  ingress_port          = var.api_receiver_port
  alb_security_group_id = module.alb.alb_security_group_id
}

module "ecs_sqs_worker_sg" {
  source       = "./modules/security_group"
  project_name = "${var.project_name}-worker"
  vpc_id       = module.vpc.vpc_id
  ingress_port = var.sqs_worker_port
}

# ...other infrastructure modules will be added here...
