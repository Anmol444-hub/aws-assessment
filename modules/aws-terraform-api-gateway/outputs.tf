output "api_id" {
  description = "HTTP API ID"
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "Base invoke URL for the default stage"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "execution_arn" {
  description = "Execution ARN prefix (used for Lambda permissions)"
  value       = aws_apigatewayv2_api.this.execution_arn
}
