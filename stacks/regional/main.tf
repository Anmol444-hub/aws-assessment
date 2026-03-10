provider "aws" {
  region = var.region
}

data "terraform_remote_state" "auth" {
  backend = "local"
  config = {
    path = "${path.root}/../auth/terraform.tfstate"
  }
}

locals {
  cognito_user_pool_id = data.terraform_remote_state.auth.outputs.user_pool_id
  cognito_client_id    = data.terraform_remote_state.auth.outputs.client_id
}

module "labels" {
  source = "../../modules/aws-terraform-labels"

  name        = var.name
  environment = var.environment
  region      = var.region
  project     = var.project
  tags        = var.tags
}

module "networking" {
  source = "../../modules/aws-terraform-networking"

  labels              = module.labels
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  azs                 = var.availability_zones
}

module "dynamodb" {
  source = "../../modules/aws-terraform-dynamodb"

  labels        = module.labels
  table_name    = "GreetingLogs"
  hash_key      = "id"
  hash_key_type = "S"
}

module "ecs" {
  source = "../../modules/aws-terraform-ecs"

  labels            = module.labels
  region            = var.region
  subnet_id         = module.networking.public_subnet_ids[0]
  security_group_id = module.networking.ecs_security_group_id

  container_name  = "publisher"
  container_image = "amazon/aws-cli:latest"
  cpu             = "256"
  memory          = "512"

  container_command = [
    "sns", "publish",
    "--topic-arn", var.sns_topic_arn,
    "--region", "us-east-1",
    "--message", jsonencode({
      email  = var.user_email
      source = "ECS"
      region = var.region
      repo   = var.repo_url
    })
  ]

  container_environment = [
    { name = "AWS_DEFAULT_REGION", value = "us-east-1" }
  ]

  task_iam_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sns:Publish"]
      Resource = [var.sns_topic_arn]
    }]
  })
}

module "lambda_greeter" {
  source = "../../modules/aws-terraform-lambda"

  labels        = module.labels
  function_name = "greeter"
  source_dir    = "${path.root}/../../lambda/greeter"
  handler       = "handler.handler"
  timeout       = 30
  memory_size   = 256

  environment_variables = {
    DYNAMODB_TABLE = module.dynamodb.table_name
    SNS_TOPIC_ARN  = var.sns_topic_arn
    EMAIL          = var.user_email
    REPO_URL       = var.repo_url
  }

  iam_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:GetItem"]
        Resource = [module.dynamodb.table_arn]
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = [var.sns_topic_arn]
      }
    ]
  })
}

module "lambda_dispatcher" {
  source = "../../modules/aws-terraform-lambda"

  labels        = module.labels
  function_name = "dispatcher"
  source_dir    = "${path.root}/../../lambda/dispatcher"
  handler       = "handler.handler"
  timeout       = 60
  memory_size   = 256

  environment_variables = {
    ECS_CLUSTER_ARN         = module.ecs.cluster_arn
    ECS_TASK_DEFINITION_ARN = module.ecs.task_definition_arn
    SUBNET_ID               = module.networking.public_subnet_ids[0]
    SECURITY_GROUP_ID       = module.networking.ecs_security_group_id
  }

  iam_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecs:RunTask"]
        Resource = [module.ecs.task_definition_arn]
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = [
          module.ecs.task_execution_role_arn,
          module.ecs.task_role_arn,
        ]
      }
    ]
  })
}

module "api_gateway" {
  source = "../../modules/aws-terraform-api-gateway"

  labels               = module.labels
  cognito_user_pool_id = local.cognito_user_pool_id
  cognito_client_id    = local.cognito_client_id

  routes = {
    "GET /greet" = {
      lambda_invoke_arn    = module.lambda_greeter.invoke_arn
      lambda_function_name = module.lambda_greeter.function_name
    }
    "POST /dispatch" = {
      lambda_invoke_arn    = module.lambda_dispatcher.invoke_arn
      lambda_function_name = module.lambda_dispatcher.function_name
    }
  }
}
