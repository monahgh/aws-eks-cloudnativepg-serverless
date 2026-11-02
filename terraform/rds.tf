resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "PostgreSQL access from EKS nodes and Lambda"
  vpc_id      = module.vpc.vpc_id

  tags = { Name = "${var.project_name}-rds-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_eks" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = module.eks.node_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "PostgreSQL from EKS nodes and pods"
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_lambda" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.lambda.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "PostgreSQL from Lambda"
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 7.2"

  identifier = "${var.project_name}-postgres"

  engine               = "postgres"
  engine_version       = var.db_engine_major_version
  family               = "postgres${var.db_engine_major_version}"
  major_engine_version = var.db_engine_major_version
  instance_class       = var.db_instance_class

  db_name  = var.db_name
  username = var.db_username

  # RDS generates the password and stores it in Secrets Manager.
  manage_master_user_password = true

  multi_az               = true
  create_db_subnet_group = false
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  create_db_option_group = false

  parameters = [
    {
      name         = "shared_preload_libraries"
      value        = "pg_stat_statements"
      apply_method = "pending-reboot"
    }
  ]

  # Lab settings: cheap and clean to destroy.
  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true
}
