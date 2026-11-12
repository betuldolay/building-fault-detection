variable "project_id" {
  type = string
}

variable "readings_topic_id" {
  description = "The platform's topic with write events."
  type        = string
}

variable "dataset_id" {
  description = "BigQuery dataset of the readings table."
  type        = string
}

variable "readings_table_id" {
  description = "Readings table, as project.dataset.table."
  type        = string
}
