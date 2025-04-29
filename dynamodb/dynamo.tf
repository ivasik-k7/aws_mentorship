resource "aws_dynamodb_table" "this" {
  name           = "${var.environment}-dynamodb-table-dataart-mentorship"
  billing_mode   = "PROVISIONED"
  write_capacity = 5
  read_capacity  = 5

  hash_key  = "PK"
  range_key = "SK"


  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  ttl {
    enabled        = true
    attribute_name = "expiredAt"
  }

  local_secondary_index {
    name            = "LSI-1"
    range_key       = "SK"
    projection_type = "KEYS_ONLY"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = merge(var.default_tags, {
    Name        = "${var.environment}-dynamodb-table-dataart-mentorship"
    Environment = var.environment
  })
}
