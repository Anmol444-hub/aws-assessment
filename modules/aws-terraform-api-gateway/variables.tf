variable "labels" {
  description = "Output object from aws-terraform-labels module"
  type = object({
    id          = string
    name        = string
    environment = string
    region      = string
    tags        = map(string)
  })
}

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID for the JWT issuer URL"
  type        = string
}

variable "cognito_client_id" {
  description = "Cognito App Client ID used as the JWT audience"
  type        = string
}

variable "routes" {
  description = <<-EOT
    Map of route key to Lambda integration config.
    Route key format: "<METHOD> <path>"  e.g. "GET /greet", "POST /dispatch"
  EOT
  type = map(object({
    lambda_invoke_arn    = string
    lambda_function_name = string
  }))
}
