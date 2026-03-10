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

variable "table_name" {
  description = "Logical table name appended to the labels ID"
  type        = string
}

variable "hash_key" {
  description = "Partition key attribute name"
  type        = string
  default     = "id"
}

variable "hash_key_type" {
  description = "Partition key attribute type: S (string), N (number), or B (binary)"
  type        = string
  default     = "S"

  validation {
    condition     = contains(["S", "N", "B"], var.hash_key_type)
    error_message = "hash_key_type must be S, N, or B."
  }
}

variable "billing_mode" {
  description = "DynamoDB billing mode (PAY_PER_REQUEST | PROVISIONED)"
  type        = string
  default     = "PAY_PER_REQUEST"
}
