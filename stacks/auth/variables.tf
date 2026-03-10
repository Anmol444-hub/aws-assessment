variable "name" {
  description = "Base resource name"
  type        = string
  default     = "unleash-live"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project tag value"
  type        = string
  default     = "unleash-live"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "user_email" {
  description = "Email address for the Cognito test user"
  type        = string
}

variable "user_temp_password" {
  description = "Temporary password set on the test user (passed via TF_VAR_ or CI secret)"
  type        = string
  sensitive   = true
}
