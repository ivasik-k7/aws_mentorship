data "aws_caller_identity" "current" {}

data "aws_availability_zones" "primary" {
  state = "available"
}

data "aws_availability_zones" "secondary" {
  provider = aws.secondary
  state    = "available"
}

data "aws_rds_engine_version" "mysql" {
  engine = "mysql"
}

data "aws_rds_orderable_db_instance" "t3_micro" {
  engine                     = "mysql"
  engine_version             = data.aws_rds_engine_version.mysql.version
  instance_class             = "db.t3.micro"
  preferred_instance_classes = ["db.t3.micro"]
}

# data "aws_secretsmanager_secret" "rds_credentials" {
#   arn        = aws_secretsmanager_secret.rds_credentials.arn
#   depends_on = [aws_secretsmanager_secret.rds_credentials]
# }

# data "aws_secretsmanager_secret_version" "rds_credentials_version" {
#   secret_id  = aws_secretsmanager_secret.rds_credentials.id
#   depends_on = [aws_secretsmanager_secret_version.rds_credentials_version]
# }
