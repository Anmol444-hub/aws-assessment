variable "bucket_name" {
  description = "Globally unique S3 bucket name for Terraform state"
  type        = string
}

variable "lock_table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "unleash-live-tfstate-lock"
}

variable "tags" {
  description = "Tags applied to bootstrap resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "unleash-live"
  }
}
