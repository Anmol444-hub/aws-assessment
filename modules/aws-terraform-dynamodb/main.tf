resource "aws_dynamodb_table" "this" {
  name         = "${var.labels.id}-${var.table_name}"
  billing_mode = var.billing_mode
  hash_key     = var.hash_key

  attribute {
    name = var.hash_key
    type = var.hash_key_type
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = var.labels.tags
}
