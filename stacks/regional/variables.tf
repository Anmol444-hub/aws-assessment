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

variable "region" {
  description = "AWS region to deploy this compute stack into"
  type        = string
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

# ---------- Networking ----------

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "One CIDR per public subnet (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  description = "AZs for the subnets"
  type        = list(string)
}

# ---------- Application ----------

variable "sns_topic_arn" {
  description = "Unleash Live verification SNS topic ARN"
  type        = string
  default     = "arn:aws:sns:us-east-1:637226132752:Candidate-Verification-Topic"
}

variable "user_email" {
  description = "Candidate email embedded in SNS payloads"
  type        = string
}

variable "repo_url" {
  description = "GitHub repository URL embedded in SNS payloads"
  type        = string
}
