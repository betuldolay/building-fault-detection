output "readings_table" {
  value = module.storage.readings_table_id
}

output "history_imports_bucket" {
  value = module.storage.history_imports_bucket
}

output "dead_letter_topic" {
  value = module.ingestion.dead_letter_topic_id
}

output "cluster_name" {
  value = module.compute.cluster_name
}

output "image_repository" {
  value = module.compute.image_repository
}

output "mysql_connection_name" {
  value = module.database.instance_connection_name
}

output "workload_service_accounts" {
  value = module.compute.workload_service_accounts
}
