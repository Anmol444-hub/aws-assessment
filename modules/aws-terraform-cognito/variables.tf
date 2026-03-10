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

variable "user_email" {
  description = "Email address for the Cognito test user (also the username)"
  type        = string
}

variable "user_temp_password" {
  description = "Temporary password for the test user — must satisfy the pool policy"
  type        = string
  sensitive   = true
}
