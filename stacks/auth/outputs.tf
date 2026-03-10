output "user_pool_id" {
  description = "Cognito User Pool ID — pass to regional stacks"
  value       = module.cognito.user_pool_id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = module.cognito.user_pool_arn
}

output "client_id" {
  description = "App Client ID — pass to regional stacks"
  value       = module.cognito.client_id
}

output "user_pool_endpoint" {
  description = "Issuer endpoint (for JWT verification)"
  value       = module.cognito.user_pool_endpoint
}
