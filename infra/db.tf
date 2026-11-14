resource "aws_security_group" "db" {
  name   = "uptime-db"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.node.id]
  }
}

resource "aws_db_instance" "main" {
  identifier                  = "uptime"
  engine                      = "postgres"
  engine_version              = "17"
  instance_class              = "db.t4g.micro"
  allocated_storage           = 20
  storage_type                = "gp3"
  storage_encrypted           = true
  db_name                     = "uptime"
  username                    = "uptime"
  manage_master_user_password = true
  db_subnet_group_name        = module.vpc.database_subnet_group_name
  vpc_security_group_ids      = [aws_security_group.db.id]
  backup_retention_period     = 0
  skip_final_snapshot         = true
}
