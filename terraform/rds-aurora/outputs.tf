output "cluster_id" {
  description = "The ID of the Aurora cluster"
  value       = aws_rds_cluster.aurora_serverless.id
}

output "cluster_arn" {
  description = "The ARN of the Aurora cluster"
  value       = aws_rds_cluster.aurora_serverless.arn
}

output "cluster_endpoint" {
  description = "Writer endpoint for the Aurora cluster"
  value       = aws_rds_cluster.aurora_serverless.endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint for the Aurora cluster"
  value       = aws_rds_cluster.aurora_serverless.reader_endpoint
}

output "cluster_port" {
  description = "Port on which the Aurora cluster accepts connections"
  value       = aws_rds_cluster.aurora_serverless.port
}

output "database_name" {
  description = "Name of the default database"
  value       = aws_rds_cluster.aurora_serverless.database_name
}

output "master_username" {
  description = "Master username for the database"
  value       = aws_rds_cluster.aurora_serverless.master_username
  sensitive   = true
}

output "master_password" {
  description = "Master password for the database"
  value       = random_password.master_password.result
  sensitive   = true
}

output "database_url" {
  description = "PostgreSQL connection URL (sensitive)"
  value       = "postgresql://${urlencode(aws_rds_cluster.aurora_serverless.master_username)}:${urlencode(random_password.master_password.result)}@${aws_rds_cluster.aurora_serverless.endpoint}:${aws_rds_cluster.aurora_serverless.port}/${aws_rds_cluster.aurora_serverless.database_name}"
  sensitive   = true
}

output "security_group_id" {
  description = "ID of the security group attached to the Aurora cluster"
  value       = aws_security_group.aurora.id
}

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "secrets_manager_secret_name" {
  description = "Name of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.db_password.name
}

# Connection string with SSL mode for application use
output "database_connection_url" {
  description = "Complete PostgreSQL connection URL with SSL mode"
  value       = "postgresql://${urlencode(aws_rds_cluster.aurora_serverless.master_username)}:${urlencode(random_password.master_password.result)}@${aws_rds_cluster.aurora_serverless.endpoint}:${aws_rds_cluster.aurora_serverless.port}/${aws_rds_cluster.aurora_serverless.database_name}?sslmode=require"
  sensitive   = true
}

# Instance information
output "instance_ids" {
  description = "IDs of the Aurora cluster instances"
  value       = aws_rds_cluster_instance.aurora_serverless_instance[*].id
}

output "instance_endpoints" {
  description = "Endpoints of the Aurora cluster instances"
  value       = aws_rds_cluster_instance.aurora_serverless_instance[*].endpoint
}
