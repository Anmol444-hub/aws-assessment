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

variable "function_name" {
  description = "Short suffix for the Lambda function (e.g. 'greeter', 'dispatcher')"
  type        = string
}

variable "source_dir" {
  description = "Absolute path to the directory containing the Lambda source code"
  type        = string
}

variable "handler" {
  description = "Handler in the form file.function"
  type        = string
  default     = "handler.handler"
}

variable "runtime" {
  description = "Lambda runtime identifier"
  type        = string
  default     = "python3.12"
}

variable "timeout" {
  description = "Function timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Function memory in MB"
  type        = number
  default     = 256
}

variable "environment_variables" {
  description = "Environment variables injected into the function"
  type        = map(string)
  default     = {}
}

variable "iam_policy_json" {
  description = "Inline IAM policy JSON granting the function any extra permissions it needs"
  type        = string
}
