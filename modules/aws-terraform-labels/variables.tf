variable "name" {
  description = "Base name for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev / staging / prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region this label set represents"
  type        = string
}

variable "project" {
  description = "Owning project name"
  type        = string
  default     = "unleash-live"
}

variable "tags" {
  description = "Additional key/value tags to merge"
  type        = map(string)
  default     = {}
}
