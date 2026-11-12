variable "project_id" {
  type = string
}

variable "location" {
  description = "Location for BigQuery and Cloud Storage. An EU location keeps data in the EU."
  type        = string
}

variable "dataset_id" {
  type    = string
  default = "fault_detection"
}

variable "deletion_protection" {
  description = "Prevent Terraform from deleting the readings table. Keep true outside throw-away environments."
  type        = bool
  default     = true
}
