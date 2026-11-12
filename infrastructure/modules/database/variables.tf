variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "network_id" {
  description = "VPC the instance gets its private IP in."
  type        = string
}

variable "private_services_connection" {
  description = "Id of the private services connection; the instance can only be created after it exists."
  type        = string
}

variable "tier" {
  description = "Machine type. Small is enough: MySQL holds signals and insights, not readings."
  type        = string
  default     = "db-custom-1-3840"
}

variable "availability_type" {
  description = "ZONAL for dev, REGIONAL (high availability) for production."
  type        = string
  default     = "ZONAL"
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "workload_service_accounts" {
  description = "Service account emails that get a database user, by workload name."
  type        = map(string)
}
