

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
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

resource "aws_iam_policy_attachment" "lambda_basic_exec" {
  name       = "lambda_basic_exec"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = local.lambda_exec_policy_arn

}

resource "aws_lambda_function" "health" {
  filename      = "hc.zip"
  function_name = "health-check-function"

  role    = aws_iam_role.lambda_exec_role.arn
  handler = "hc.lambda_handler"
  runtime = "python3.9"

  timeout          = 10
  memory_size      = 128
  source_code_hash = filebase64sha256("${path.module}/hc.zip")
}

resource "aws_lambda_function" "whoami" {
  filename      = "sts.zip"
  function_name = "whoami-function"

  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "sts.lambda_handler"
  runtime          = "python3.9"
  timeout          = 10
  memory_size      = 128
  source_code_hash = filebase64sha256("${path.module}/sts.zip")
}


data "archive_file" "hc_zip" {
  type        = "zip"
  output_path = "${path.module}/hc.zip"
  source_file = "${path.module}/hc.py"
}

data "archive_file" "sts_zip" {
  type        = "zip"
  output_path = "${path.module}/sts.zip"
  source_file = "${path.module}/sts.py"
}
