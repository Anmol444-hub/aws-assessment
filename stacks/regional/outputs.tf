output "region" {
  description = "Region this stack was deployed to"
  value       = var.region
}

output "api_endpoint" {
  description = "API Gateway base URL (append /greet or /dispatch)"
  value       = module.api_gateway.api_endpoint
}

output "dynamodb_table_name" {
  description = "GreetingLogs DynamoDB table name"
  value       = module.dynamodb.table_name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = module.ecs.cluster_arn
}

output "greeter_function_name" {
  description = "Greeter Lambda function name"
  value       = module.lambda_greeter.function_name
}

output "dispatcher_function_name" {
  description = "Dispatcher Lambda function name"
  value       = module.lambda_dispatcher.function_name
}
