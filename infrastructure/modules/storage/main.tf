# Where all readings live: one BigQuery table, filled by Pub/Sub (module "ingestion") and by history imports.

resource "google_bigquery_dataset" "readings" {
  dataset_id  = var.dataset_id
  location    = var.location
  description = "Sensor readings from the IoT platform."
}

resource "google_bigquery_table" "readings" {
  dataset_id          = google_bigquery_dataset.readings.dataset_id
  table_id            = "readings"
  description         = "One row per reading, as received. Never updated, only added."
  deletion_protection = var.deletion_protection

  # One partition per day of measurement: loading a building's last week reads ~8 partitions, not years.
  time_partitioning {
    type  = "DAY"
    field = "measured_at"
  }
  require_partition_filter = true # a query without a time filter would read (and bill) all history

  # Within a day, rows are sorted by building, so one building's data is read cheaply.
  clustering = ["building_id", "equipment_id", "sensor_id"]

  # Field names follow the platform's write event. "value" is number | boolean in the event, so it is split
  # into two columns by the message transform in module "ingestion".
  schema = jsonencode([
    { name = "building_id", type = "STRING", mode = "REQUIRED" },
    { name = "equipment_id", type = "STRING", mode = "REQUIRED" },
    { name = "sensor_id", type = "STRING", mode = "REQUIRED" },
    { name = "measured_at", type = "TIMESTAMP", mode = "REQUIRED", description = "When the value was measured." },
    { name = "value_number", type = "FLOAT64", mode = "NULLABLE", description = "Set when the value is a number." },
    { name = "value_bool", type = "BOOL", mode = "NULLABLE", description = "Set when the value is a boolean." },
    { name = "unit", type = "STRING", mode = "NULLABLE" },
    { name = "tags", type = "STRING", mode = "REPEATED" },
  ])
}

# Landing place for the platform's batch exports (history of a building that joins).
# A load job copies them into the readings table; the files are not needed after that.
resource "google_storage_bucket" "history_imports" {
  name                        = "${var.project_id}-history-imports"
  location                    = var.location
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}
