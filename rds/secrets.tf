# resource "aws_secretsmanager_secret" "rds_credentials" {
#   name        = "rds-credentials"
#   description = "RDS username and password"
# }

# resource "aws_secretsmanager_secret_version" "rds_credentials_version" {
#   secret_id = aws_secretsmanager_secret.rds_credentials.id
#   secret_string = jsonencode({
#     username = var.db_user
#     password = var.db_password
#   })
# }
