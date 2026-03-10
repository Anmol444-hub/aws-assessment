locals {
  id          = "${var.name}-${var.environment}-${var.region}"
  name        = var.name
  environment = var.environment
  region      = var.region

  tags = merge(
    {
      Name        = "${var.name}-${var.environment}-${var.region}"
      Environment = var.environment
      Region      = var.region
      ManagedBy   = "Terraform"
      Project     = var.project
    },
    var.tags,
  )
}