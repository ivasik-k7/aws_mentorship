# locals {
#   rds_credentials = jsondecode(data.aws_secretsmanager_secret_version.rds_credentials_version.secret_string)
# }

# resource "aws_security_group" "db" {
#   vpc_id      = module.vpc.vpc_id
#   name        = "${var.environment}-rds-sg-${data.aws_caller_identity.current.account_id}"
#   description = "Security group for RDS instance"

#   ingress {
#     from_port   = 3306
#     to_port     = 3306
#     protocol    = "tcp"
#     cidr_blocks = ["10.0.0.0/16"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = merge(var.default_tags, {
#     Name = "${var.environment}-rds-sg-${data.aws_caller_identity.current.account_id}"
#   })
# }




# resource "aws_db_subnet_group" "main_sng" {
#   name        = "${var.environment}-rds-subnet-group-${data.aws_caller_identity.current.account_id}"
#   description = "RDS subnet group"

#   # Which subnets should be for db subnet group
#   subnet_ids = []

#   tags = merge(var.default_tags, {
#     Name = "${var.environment}-rds-subnet-group-${data.aws_caller_identity.current.account_id}"
#   })
# }

# resource "aws_db_subnet_group" "replica_sng" {
#   name        = "${var.environment}-rds-replica-subnet-group-${data.aws_caller_identity.current.account_id}"
#   description = "RDS replica subnet group"
#   provider    = aws.secondary

#   # Which subnets should be for db subnet group
#   subnet_ids = []

#   tags = merge(var.default_tags, {
#     Name = "${var.environment}-rds-replica-subnet-group-${data.aws_caller_identity.current.account_id}"
#   })
# }

# resource "aws_db_subnet_group" "main" {

# }


# resource "aws_db_subnet_group" "replica" {
#   name        = "${var.environment}-rds-replica-subnet-group-${data.aws_caller_identity.current.account_id}"
#   description = "RDS replica subnet group"
#   subnet_ids  = module.vpc.private_subnet_ids
#   # provider    = aws.secondary
#   tags = merge(var.default_tags, {
#     Name = "${var.environment}-rds-replica-subnet-group-${data.aws_caller_identity.current.account_id}"
#   })
# }



# resource "aws_db_instance" "primary" {
#   count      = 0
#   identifier = "primary-${var.environment}-${data.aws_caller_identity.current.account_id}"
#   engine     = "mysql"

#   engine_version = data.aws_rds_engine_version.mysql.version
#   instance_class = data.aws_rds_orderable_db_instance.t3_micro.instance_class

#   multi_az            = true
#   skip_final_snapshot = true

#   storage_type      = "gp2"
#   allocated_storage = 20

#   db_name  = "globaldb"
#   username = local.rds_credentials.username
#   password = local.rds_credentials.password

#   backup_retention_period = 7
#   backup_window           = "03:00-04:00"
#   maintenance_window      = "mon:04:00-mon:04:30"

#   db_subnet_group_name   = aws_db_subnet_group.main.name
#   vpc_security_group_ids = [aws_security_group.db.id]

#   tags = merge(var.default_tags, {
#     Name = "${var.environment}-rds-${data.aws_caller_identity.current.account_id}"
#   })
# }

# resource "aws_db_instance" "replica" {
#   count               = 0
#   identifier          = "replica-${var.environment}-${data.aws_caller_identity.current.account_id}"
#   replicate_source_db = aws_db_instance.primary.arn
#   provider            = aws.secondary

#   engine         = "mysql"
#   engine_version = data.aws_rds_engine_version.mysql.version
#   instance_class = data.aws_rds_orderable_db_instance.t3_micro.instance_class

#   skip_final_snapshot = true

#   #   db_subnet_group_name  = aws_db_subnet_group.replica.name
#   vpc_security_group_ids = [aws_security_group.db.id]

#   tags = merge(var.default_tags, {
#     Name = "${var.environment}-rds-replica-${data.aws_caller_identity.current.account_id}"
#   })

# }

# # resource "aws_db_instance" "replica" {
# # }
