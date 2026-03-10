output "id" {
  description = "Normalized resource ID: <name>-<environment>"
  value       = local.id
}

output "name" {
  description = "Base name"
  value       = local.name
}

output "environment" {
  description = "Environment string"
  value       = local.environment
}

output "region" {
  description = "AWS region"
  value       = local.region
}

output "tags" {
  description = "Merged tag map to apply to every resource"
  value       = local.tags
}
