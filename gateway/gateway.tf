resource "aws_api_gateway_rest_api" "this" {
  name        = "AWS Mentorship Demo API"
  description = "Demo API for AWS Mentorship"


  endpoint_configuration {
    types = ["REGIONAL"]
  }

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "execute-api:Invoke"
        Resource  = "*"
      }
    ]
  })

  tags = merge(var.default_tags, {
    Name = "AWS Mentorship Demo API"
  })

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
  }
}

resource "aws_api_gateway_domain_name" "api" {
  regional_certificate_arn = data.aws_acm_certificate.certificate.arn
  domain_name              = var.domain_name

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.sts
  ]
}

resource "aws_api_gateway_stage" "dev" {
  stage_name  = "dev"
  description = "Development stage for AWS Mentorship Demo API"

  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
}

resource "aws_lambda_permission" "allow_api_gateway_lambdas" {
  principal    = "apigateway.amazonaws.com"
  action       = "lambda:InvokeFunction"
  statement_id = "AllowAPIGatewayInvoke"

  for_each = {
    for lambda in [aws_lambda_function.whoami, aws_lambda_function.health] :
    lambda.function_name => lambda
  }
  function_name = each.value.function_name
}

resource "aws_api_gateway_resource" "sts" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "sts"
}

resource "aws_api_gateway_method" "sts" {
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.sts.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "sts" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.sts.id
  http_method             = aws_api_gateway_method.sts.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.whoami.invoke_arn
}

resource "aws_api_gateway_method_response" "sts" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.sts.id
  http_method = aws_api_gateway_method.sts.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "sts" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.sts.id
  http_method = aws_api_gateway_method.sts.http_method
  status_code = aws_api_gateway_method_response.sts.status_code

  depends_on = [
    aws_api_gateway_integration.sts
  ]
}

# resource "aws_api_gateway_resource" "hc" {
#   rest_api_id = aws_api_gateway_rest_api.this.id
#   parent_id   = aws_api_gateway_rest_api.this.root_resource_id
#   path_part   = "hc"
# }

# resource "aws_api_gateway_method" "hc" {
#   http_method   = "GET"
#   resource_id   = aws_api_gateway_rest_api.this.root_resource_id
#   rest_api_id   = aws_api_gateway_rest_api.this.id
#   authorization = "NONE"
# }


# resource "aws_api_gateway_integration" "hc" {
#   rest_api_id             = aws_api_gateway_rest_api.this.id
#   resource_id             = aws_api_gateway_resource.hc.id
#   http_method             = aws_api_gateway_method.hc.http_method
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.health.invoke_arn
# }

# resource "aws_api_gateway_method_response" "hc" {
#   rest_api_id = aws_api_gateway_rest_api.this.id
#   resource_id = aws_api_gateway_resource.hc.id
#   http_method = aws_api_gateway_method.hc.http_method
#   status_code = "200"
# }

# resource "aws_api_gateway_integration_response" "hc" {
#   rest_api_id = aws_api_gateway_rest_api.this.id
#   resource_id = aws_api_gateway_resource.hc.id
#   http_method = aws_api_gateway_method.hc.http_method
#   status_code = aws_api_gateway_method_response.hc.status_code

#   depends_on = [
#     aws_api_gateway_integration.hc
#   ]
# }
