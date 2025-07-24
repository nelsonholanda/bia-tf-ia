# RDS Module for BIA Application

# DB Subnet Group
resource "aws_db_subnet_group" "bia" {
  name       = "bia-${var.environment}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-subnet-group"
  })
}

resource "aws_db_instance" "bia" {
  identifier     = "bia-${var.environment}-db"
  engine         = "postgres"
  engine_version = "17.4"
  instance_class = "db.t3.micro"

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp2"
  storage_encrypted     = false

  db_name  = var.database_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = var.security_group_ids
  db_subnet_group_name   = aws_db_subnet_group.bia.name

  multi_az                = var.environment == "prod" ? true : false
  backup_retention_period = var.environment == "prod" ? 7 : 1
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  skip_final_snapshot = true
  deletion_protection = false

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-db"
  })
}