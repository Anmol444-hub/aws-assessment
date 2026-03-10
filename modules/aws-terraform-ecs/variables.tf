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

variable "region" {
  description = "AWS region in which this ECS cluster runs"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID for Fargate task network placement"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID attached to Fargate tasks"
  type        = string
}

variable "task_iam_policy_json" {
  description = "IAM policy JSON granted to the task role (e.g. sns:Publish)"
  type        = string
}

variable "container_name" {
  description = "Name of the container inside the task definition"
  type        = string
  default     = "app"
}

variable "container_image" {
  description = "Docker image for the container (e.g. amazon/aws-cli:latest)"
  type        = string
}

variable "container_command" {
  description = "Command passed to the container (overrides the image CMD)"
  type        = list(string)
}

variable "container_environment" {
  description = "List of environment variable maps ({ name, value }) injected into the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "cpu" {
  description = "Task-level CPU units (256 | 512 | 1024 | 2048 | 4096)"
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Task-level memory in MiB"
  type        = string
  default     = "512"
}
