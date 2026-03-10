output "bucket_name" {
  description = "S3 bucket name — use this in all backend configs"
  value       = aws_s3_bucket.tfstate.id
}

output "lock_table_name" {
  description = "DynamoDB lock table name"
  value       = aws_dynamodb_table.tflock.name
}
