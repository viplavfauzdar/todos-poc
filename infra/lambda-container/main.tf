terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# -----------------------------
# Variables
# -----------------------------
variable "region" {
  description = "AWS region"
  type        = string
}

variable "function_name" {
  description = "Lambda function name"
  type        = string
  default     = "todos-poc"
}

variable "image_uri" {
  description = "ECR image URI with tag for Lambda container"
  type        = string
}

variable "timeout" {
  description = "Function timeout in seconds"
  type        = number
  default     = 20
}

variable "memory_size" {
  description = "Memory size (MB)"
  type        = number
  default     = 1024
}

variable "architecture" {
  description = "Lambda architecture"
  type        = string
  default     = "x86_64"
}

# -----------------------------
# IAM role for Lambda execution
# -----------------------------
resource "aws_iam_role" "lambda_exec" {
  name = "${var.function_name}-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

data "aws_iam_policy" "lambda_basic" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_basic_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = data.aws_iam_policy.lambda_basic.arn
}

# -----------------------------
# Lambda function (container image)
# -----------------------------
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  package_type  = "Image"
  role          = aws_iam_role.lambda_exec.arn
  image_uri     = var.image_uri
  timeout       = var.timeout
  memory_size   = var.memory_size
  architectures = [var.architecture]
}

# -----------------------------
# Function URL (public, no-auth)
# -----------------------------
resource "aws_lambda_function_url" "this" {
  function_name      = aws_lambda_function.this.function_name
  authorization_type = "NONE"
}

# -----------------------------
# Outputs
# -----------------------------
output "lambda_function_name" {
  value       = aws_lambda_function.this.function_name
  description = "Name of the Lambda function"
}

output "lambda_function_url" {
  value       = aws_lambda_function_url.this.function_url
  description = "Public Function URL"
}