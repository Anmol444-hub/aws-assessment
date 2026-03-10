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

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "azs" {
  description = "Availability zones to deploy subnets into"
  type        = list(string)
}
