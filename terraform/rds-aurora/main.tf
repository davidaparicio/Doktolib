terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Use assume_role for secure, temporary credentials
  dynamic "assume_role" {
    for_each = var.assume_role_arn != "" ? [1] : []
    content {
      role_arn    = var.assume_role_arn
      external_id = var.assume_role_external_id
      session_name = "qovery-doktolib-rds-aurora"
    }
  }
}

# Generate random password for database
resource "random_password" "master_password" {
  length  = 32
  special = true
  # Aurora doesn't allow these characters in passwords
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# VPC Data Source (using default VPC or specify your own)
data "aws_vpc" "selected" {
  default = var.use_default_vpc
  id      = var.use_default_vpc ? null : var.vpc_id
}

# Get available subnets
data "aws_subnets" "available" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

# Create DB subnet group
resource "aws_db_subnet_group" "aurora" {
  name       = "${var.cluster_name}-subnet-group"
  subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : data.aws_subnets.available.ids

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-subnet-group"
    }
  )
}

# Security group for Aurora cluster
resource "aws_security_group" "aurora" {
  name        = "${var.cluster_name}-sg"
  description = "Security group for Aurora Serverless cluster ${var.cluster_name}"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "PostgreSQL access from allowed CIDR blocks"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-sg"
    }
  )
}

# RDS Aurora Serverless v2 Cluster
resource "aws_rds_cluster" "aurora_serverless" {
  cluster_identifier     = var.cluster_name
  engine                 = "aurora-postgresql"
  engine_mode            = "provisioned"
  engine_version         = var.engine_version
  database_name          = var.database_name
  master_username        = var.master_username
  master_password        = random_password.master_password.result

  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [aws_security_group.aurora.id]

  # Serverless v2 scaling configuration
  serverlessv2_scaling_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  # Backup configuration
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window

  # Encryption
  storage_encrypted = true
  kms_key_id        = var.kms_key_id

  # Additional settings
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.cluster_name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  apply_immediately         = var.apply_immediately
  enabled_cloudwatch_logs_exports = ["postgresql"]

  # Allow major version upgrades
  allow_major_version_upgrade = true

  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
    }
  )
}

# Aurora Serverless v2 Instance
resource "aws_rds_cluster_instance" "aurora_serverless_instance" {
  count              = var.instance_count
  identifier         = "${var.cluster_name}-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora_serverless.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora_serverless.engine
  engine_version     = aws_rds_cluster.aurora_serverless.engine_version

  publicly_accessible = var.publicly_accessible

  performance_insights_enabled = var.performance_insights_enabled

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-instance-${count.index + 1}"
    }
  )
}

# Store password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.cluster_name}-master-password"
  description = "Master password for Aurora Serverless cluster ${var.cluster_name}"

  recovery_window_in_days = var.secret_recovery_days

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-master-password"
    }
  )
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username            = aws_rds_cluster.aurora_serverless.master_username
    password            = random_password.master_password.result
    engine              = "postgres"
    host                = aws_rds_cluster.aurora_serverless.endpoint
    port                = aws_rds_cluster.aurora_serverless.port
    dbname              = aws_rds_cluster.aurora_serverless.database_name
    dbClusterIdentifier = aws_rds_cluster.aurora_serverless.cluster_identifier
  })
}
