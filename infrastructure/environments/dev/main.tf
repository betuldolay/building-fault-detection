# Building Fault Detection - development environment.
# Mirrors the architecture in section 5 of the design document:
#
#   IoT platform --readings--> Pub/Sub --BigQuery subscription--> BigQuery (readings)
#                --batch exports--> Cloud Storage --load job------^
#   Nightly Kubernetes job (rule engine) reads BigQuery, writes MySQL; the insights API reads both.

locals {
  name = "fault-detection"
}

resource "google_project_service" "apis" {
  for_each = toset([
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "pubsub.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
  ])

  service            = each.key
  disable_on_destroy = false
}

module "iot_platform" {
  source            = "../../modules/iot_platform"
  readings_topic_id = var.platform_readings_topic_id
}

module "network" {
  source = "../../modules/network"
  name   = local.name
  region = var.region

  depends_on = [google_project_service.apis]
}

module "storage" {
  source              = "../../modules/storage"
  project_id          = var.project_id
  location            = var.data_location
  deletion_protection = var.deletion_protection

  depends_on = [google_project_service.apis]
}

module "ingestion" {
  source            = "../../modules/ingestion"
  project_id        = var.project_id
  readings_topic_id = module.iot_platform.readings_topic_id
  dataset_id        = module.storage.dataset_id
  readings_table_id = module.storage.readings_table_id
}

module "compute" {
  source                 = "../../modules/compute"
  project_id             = var.project_id
  name                   = local.name
  region                 = var.region
  network_id             = module.network.network_id
  subnetwork_id          = module.network.subnetwork_id
  pods_range_name        = module.network.pods_range_name
  services_range_name    = module.network.services_range_name
  readings_dataset_id    = module.storage.dataset_id
  history_imports_bucket = module.storage.history_imports_bucket
  deletion_protection    = var.deletion_protection
}

module "database" {
  source                      = "../../modules/database"
  name                        = local.name
  region                      = var.region
  network_id                  = module.network.network_id
  private_services_connection = module.network.private_services_connection
  deletion_protection         = var.deletion_protection

  workload_service_accounts = {
    rule-engine  = module.compute.workload_service_accounts["rule-engine"]
    insights-api = module.compute.workload_service_accounts["insights-api"]
  }
}
