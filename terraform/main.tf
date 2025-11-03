terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  backend "s3" {
    bucket = "aetna-infra-tf-bucket"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# ECS Cluster
module "ecs" {
  source = "./modules/ecs"

  app_name        = var.app_name
  environment     = var.environment
  container_image = var.container_image
  container_port  = var.container_port
  cpu             = var.cpu
  memory          = var.memory
  desired_count   = var.desired_count
  aws_region      = var.aws_region
}

# S3 Bucket
module "s3" {
  source = "./modules/s3"

  app_name    = var.app_name
  environment = var.environment
}

# CloudWatch Alarms
module "cloudwatch" {
  source = "./modules/cloudwatch"

  app_name         = var.app_name
  environment      = var.environment
  ecs_cluster_name = module.ecs.cluster_name
  ecs_service_name = module.ecs.service_name
  log_group_name   = module.ecs.log_group_name
  alert_email      = var.alert_email
}

# Outputs
output "service_url" {
  description = "URL of the deployed ECS service"
  value       = module.ecs.service_url
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3.bucket_name
}

output "cloudwatch_alarm_names" {
  description = "Names of CloudWatch alarms"
  value       = module.cloudwatch.alarm_names
}

