terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50.0"
    }
  }
}

# -----------------------------
# Variables
# -----------------------------
variable "region" {
  description = "AWS region"
  type        = string
}

variable "service_name" {
  description = "App Runner service name"
  type        = string
  default     = "todos-poc"
}

variable "image_identifier" {
  description = "ECR image URI with tag, e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/todos-poc:latest"
  type        = string
}

variable "port" {
  description = "Container port"
  type        = string
  default     = "8080"
}

variable "health_path" {
  description = "HTTP health check path"
  type        = string
  default     = "/actuator/health"
}

variable "cpu" {
  description = "vCPU setting (allowed: '1 vCPU', '2 vCPU')"
  type        = string
  default     = "1 vCPU"
}

variable "memory" {
  description = "Memory setting (allowed: '2 GB', '3 GB', '4 GB')"
  type        = string
  default     = "2 GB"
}

variable "auto_deploy" {
  description = "Enable auto-deploy from ECR when a new image tag is pushed"
  type        = bool
  default     = true
}

variable "env" {
  description = "Environment variables to inject into the container"
  type        = map(string)
  default     = {}
}

provider "aws" {
  region = var.region
}

# Convert env map to the list structure App Runner expects
locals {
  runtime_env = [for k, v in var.env : { name = k, value = v }]
}

# -----------------------------
# IAM role for App Runner to pull from ECR
# -----------------------------
# App Runner needs an access role with the service principal 'build.apprunner.amazonaws.com'
# and the AWS managed policy AWSAppRunnerServicePolicyForECRAccess.
resource "aws_iam_role" "apprunner_ecr_access" {
  name = "${var.service_name}-apprunner-ecr-access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "build.apprunner.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

data "aws_iam_policy" "apprunner_ecr_policy" {
  arn = "arn:aws:iam::aws:policy/AWSAppRunnerServicePolicyForECRAccess"
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.apprunner_ecr_access.name
  policy_arn = data.aws_iam_policy.apprunner_ecr_policy.arn
}

# -----------------------------
# App Runner service
# -----------------------------
resource "aws_apprunner_service" "this" {
  service_name = var.service_name

  source_configuration {
    auto_deployments_enabled = var.auto_deploy

    image_repository {
      image_repository_type = "ECR"
      image_identifier      = var.image_identifier

      image_configuration {
        port                          = var.port
        runtime_environment_variables = local.runtime_env
      }
    }

    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_access.arn
    }
  }

  instance_configuration {
    cpu    = var.cpu
    memory = var.memory
  }

  health_check_configuration {
    protocol = "HTTP"
    path     = var.health_path
  }

  tags = {
    Project = var.service_name
  }
}

output "service_arn" {
  value       = aws_apprunner_service.this.arn
  description = "App Runner service ARN"
}

output "service_url" {
  value       = aws_apprunner_service.this.service_url
  description = "Public default domain for the App Runner service"
}