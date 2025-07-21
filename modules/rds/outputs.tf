output "db_endpoint" {
  value = var.use_aurora ? aws_rds_cluster.aurora[0].endpoint : aws_db_instance.standard[0].address
}

output "db_name" {
  value = var.db_name
}

output "db_username" {
  value = var.username
}

output "aurora_writer_endpoint" {
  value       = try(aws_rds_cluster.aurora[0].endpoint, null)
  description = "Endpoint для записи в Aurora"
}

output "aurora_reader_endpoints" {
  value       = try(aws_rds_cluster.aurora[0].reader_endpoint, null)
  description = "Endpoint для чтения в Aurora"
}
