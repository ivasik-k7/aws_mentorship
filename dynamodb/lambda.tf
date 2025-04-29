
data "archive_file" "read_zip" {
  type        = "zip"
  output_path = "${path.module}/read.zip"
  source_file = "${path.module}/read.py"
}

data "archive_file" "write_zip" {
  type        = "zip"
  output_path = "${path.module}/write.zip"
  source_file = "${path.module}/write.py"
}

resource "aws_iam_policy" "dynamo_access_policy" {
  name        = "dynamo-access-policy"
  description = "Policy for Lambda to access DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = "arn:aws:dynamodb:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}


resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.environment}-lambda-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.dynamo_access_policy.arn
}


resource "aws_lambda_function" "read" {
  handler          = "read.lambda_handler"
  function_name    = "${var.environment}-read-function"
  filename         = data.archive_file.read_zip.output_path
  runtime          = "python3.9"
  timeout          = 15
  memory_size      = 128
  source_code_hash = data.archive_file.read_zip.output_base64sha256

  role = aws_iam_role.lambda_exec_role.arn

  tags = merge(var.default_tags, {
    Name        = "${var.environment}-read-function"
    Environment = var.environment
  })
}

resource "aws_lambda_function" "write" {
  handler          = "write.lambda_handler"
  function_name    = "${var.environment}-write-function"
  filename         = data.archive_file.write_zip.output_path
  runtime          = "python3.9"
  timeout          = 15
  memory_size      = 128
  source_code_hash = data.archive_file.write_zip.output_base64sha256

  role = aws_iam_role.lambda_exec_role.arn

  tags = merge(var.default_tags, {
    Name        = "${var.environment}-write-function"
    Environment = var.environment
  })
}
