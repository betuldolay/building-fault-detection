output "dataset_id" {
  value = google_bigquery_dataset.readings.dataset_id
}

output "readings_table_id" {
  description = "In the form project.dataset.table, as a BigQuery subscription expects."
  value       = "${google_bigquery_table.readings.project}.${google_bigquery_table.readings.dataset_id}.${google_bigquery_table.readings.table_id}"
}

output "history_imports_bucket" {
  value = google_storage_bucket.history_imports.name
}
