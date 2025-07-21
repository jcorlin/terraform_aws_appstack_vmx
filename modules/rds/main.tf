resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.name_prefix}-rds-subnet-group"
  }
}

resource "aws_kms_key" "rds_kms_key" {
  description         = "KMS key for RDS cluster encryption"
  enable_key_rotation = true
}

resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Allow Postgres access from app subnets"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from within VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-rds-security-group"
  }
}

resource "aws_rds_cluster" "this" {
  cluster_identifier      = "${var.name_prefix}-rds-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = "15.10"
  master_username         = var.db_user
  master_password         = var.db_password
  database_name           = var.db_name
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.this.id]
  skip_final_snapshot     = true
  backup_retention_period = 7
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.rds_kms_key.arn
  preferred_backup_window = "07:00-09:00"

  tags = {
    Name = "${var.name_prefix}-rds-cluster"
  }
}

resource "aws_rds_cluster_instance" "writer" {
  identifier           = "${var.name_prefix}-rds-cluster-writer"
  cluster_identifier   = aws_rds_cluster.this.id
  instance_class       = "db.t4g.medium"
  engine               = "aurora-postgresql"
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.this.name

  tags = {
    Name = "${var.name_prefix}-rds-cluster-writer"
  }
}
