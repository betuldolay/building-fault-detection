output "instance_connection_name" {
  description = "Used by the Cloud SQL Auth Proxy next to each workload, as project:region:instance."
  value       = google_sql_database_instance.main.connection_name
}

output "database_name" {
  value = google_sql_database.insights.name
}
