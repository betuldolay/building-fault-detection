variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "network_id" {
  type = string
}

variable "subnetwork_id" {
  type = string
}

variable "pods_range_name" {
  type = string
}

variable "services_range_name" {
  type = string
}

variable "readings_dataset_id" {
  description = "Dataset with the readings table."
  type        = string
}

variable "history_imports_bucket" {
  description = "Bucket with the platform's batch exports."
  type        = string
}

variable "kubernetes_namespace" {
  description = "Namespace the workloads run in."
  type        = string
  default     = "fault-detection"
}

variable "deletion_protection" {
  type    = bool
  default = true
}
