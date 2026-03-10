terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "/tmp/terraform-${var.labels.id}-${var.function_name}.zip"
}

# ---------- IAM ----------

resource "aws_iam_role" "exec" {
  name = "${var.labels.id}-${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = var.labels.tags
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "custom" {
  name   = "${var.labels.id}-${var.function_name}-policy"
  role   = aws_iam_role.exec.id
  policy = var.iam_policy_json
}

# ---------- Function ----------

resource "aws_lambda_function" "this" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "${var.labels.id}-${var.function_name}"
  role             = aws_iam_role.exec.arn
  handler          = var.handler
  runtime          = var.runtime
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = var.timeout
  memory_size      = var.memory_size

  environment {
    variables = var.environment_variables
  }

  tags = var.labels.tags
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.this.function_name}"
  retention_in_days = 7
  tags              = var.labels.tags
}
