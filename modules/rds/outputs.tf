output "writer_endpoint" {
  description = "Cluster endpoint for write operations (Django should use this)"
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Read-only endpoint, load balanced across replicas"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "db_name" {
  description = "The initial database name"
  value       = aws_rds_cluster.this.database_name
}

output "security_group_id" {
  description = "Security group ID for Aurora cluster access"
  value       = aws_security_group.this.id
}

output "db_subnet_group_name" {
  description = "Subnet group name used by Aurora cluster"
  value       = aws_db_subnet_group.this.name
}
