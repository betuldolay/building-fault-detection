variable "project_id" {
  description = "GCP project for this environment."
  type        = string
}

variable "region" {
  description = "Region for the cluster, MySQL and the network. Netherlands, so data stays in the EU."
  type        = string
  default     = "europe-west4"
}

variable "data_location" {
  description = "Location for BigQuery and Cloud Storage."
  type        = string
  default     = "EU"
}

variable "platform_readings_topic_id" {
  description = "The IoT platform's Pub/Sub topic with write events, e.g. projects/iot-platform/topics/sensor-readings."
  type        = string
}

variable "deletion_protection" {
  description = "Protect data and the cluster from `terraform destroy`. False only for throw-away environments."
  type        = bool
  default     = true
}
