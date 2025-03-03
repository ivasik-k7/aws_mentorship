data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}

data "aws_route_tables" "default" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}

locals {
  vpc_id = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default.id
}

resource "aws_s3_bucket" "main" {
  count = var.is_s3_create ? 1 : 0

  bucket = var.bucket_name
  tags   = var.default_tags
}

resource "aws_s3_bucket_versioning" "main" {
  count = var.is_s3_create ? 1 : 0

  depends_on = [aws_s3_bucket.main]
  bucket     = aws_s3_bucket.main[count.index].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count = var.is_s3_create ? 1 : 0

  depends_on = [aws_s3_bucket.main]
  bucket     = aws_s3_bucket.main[count.index].id

  rule {
    id     = "standard-to-glacier"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 60
      storage_class = "GLACIER"
    }
    expiration {
      days = 90
    }
  }

  rule {
    id     = "noncurrent-cleanup"
    status = "Enabled"

    filter {}

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  rule {
    id     = "cleanup-expired-delete-markers"
    status = "Enabled"

    filter {}

    expiration {
      expired_object_delete_marker = true
    }
  }

  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count = var.is_s3_create ? 1 : 0

  depends_on = [aws_s3_bucket.main]
  bucket     = aws_s3_bucket.main[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  count = var.is_s3_create ? 1 : 0

  depends_on = [aws_s3_bucket.main]
  bucket     = aws_s3_bucket.main[count.index].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#######################


resource "aws_dynamodb_table" "main" {
  count = var.is_dynamo_create ? 1 : 0

  name = var.dynamo_table_name

  hash_key = "id"
  attribute {
    name = "id"
    type = "S"
  }

  billing_mode = "PROVISIONED"

  read_capacity  = 5
  write_capacity = 5

  ttl {
    enabled        = true
    attribute_name = "expiry_time"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = var.default_tags
}

resource "aws_appautoscaling_target" "dynamo_read_target" {
  count = var.is_dynamo_create ? 1 : 0


  max_capacity = 10
  min_capacity = 5

  resource_id = "table/${aws_dynamodb_table.main[count.index].name}"

  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"

}

resource "aws_appautoscaling_policy" "dynamo_read_policy" {
  count = var.is_dynamo_create ? 1 : 0

  name        = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.dynamo_read_target[count.index].resource_id}"
  policy_type = "TargetTrackingScaling"

  resource_id        = aws_appautoscaling_target.dynamo_read_target[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.dynamo_read_target[count.index].scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamo_read_target[count.index].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    target_value = 75
  }
}

resource "aws_appautoscaling_target" "dynamo_write_target" {
  count = var.is_dynamo_create ? 1 : 0

  max_capacity = 10
  min_capacity = 5

  resource_id = "table/${aws_dynamodb_table.main[count.index].name}"

  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamo_write_policy" {
  count = var.is_dynamo_create ? 1 : 0

  name        = "DynamoDBWriteCapacityUtilization:${aws_appautoscaling_target.dynamo_write_target[count.index].resource_id}"
  policy_type = "TargetTrackingScaling"

  resource_id        = aws_appautoscaling_target.dynamo_write_target[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.dynamo_write_target[count.index].scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamo_write_target[count.index].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    target_value = 75
  }
}


resource "aws_vpc_endpoint" "s3_gateway" {
  count = var.is_s3_create ? 1 : 0

  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  vpc_id = local.vpc_id
  # security_group_ids = var.security_group_ids
  # subnet_ids      = data.aws_subnets.default.ids
  # route_table_ids = data.aws_route_tables.default.ids

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.main[0].arn,
          "${aws_s3_bucket.main[0].arn}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:SourceVpce" = "${var.vpc_id}"
          }
        }
      }
    ]
  })

  tags = merge(var.default_tags, {
    "name" : "s3-gateway-endpoint"
  })
}


resource "aws_vpc_endpoint" "dynamo_gateway" {
  count = var.is_dynamo_create ? 1 : 0

  service_name      = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type = "Gateway"

  vpc_id = local.vpc_id
  # security_group_ids = var.security_group_ids
  # subnet_ids      = data.aws_subnets.default.ids
  # route_table_ids = data.aws_route_tables.default.ids

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.main[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceVpce" = "${var.vpc_id}"
          }
        }
      }
    ]
  })

  tags = merge(var.default_tags, {
    "name" : "dynamo-gateway-endpoint"
  })
}
