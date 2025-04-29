output "user_pool_id" {
  value = aws_cognito_user_pool.this.id
}

output "user_pool_name" {
  value = aws_cognito_user_pool.this.name
}

output "user_pool_arn" {
  value = aws_cognito_user_pool.this.arn
}

output "app_client_id" {
  value = aws_cognito_user_pool_client.this.id
}

output "identity_pool_id" {
  value = aws_cognito_identity_pool.this.id
}

output "authenticated_role_arn" {
  value = aws_iam_role.authenticated_role.arn
}
