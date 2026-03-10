output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

output "task_definition_arn" {
  description = "Task definition ARN (latest active revision)"
  value       = aws_ecs_task_definition.this.arn
}

output "task_execution_role_arn" {
  description = "Task execution role ARN (needed for iam:PassRole in Dispatcher Lambda)"
  value       = aws_iam_role.task_execution.arn
}

output "task_role_arn" {
  description = "Task role ARN (needed for iam:PassRole in Dispatcher Lambda)"
  value       = aws_iam_role.task_role.arn
}
