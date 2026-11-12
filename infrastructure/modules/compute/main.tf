# Where our code runs: one Kubernetes cluster (GKE Autopilot), an image registry, and one service account per
# workload with only the rights it needs.
#
# The workloads themselves (the nightly rule-engine CronJob, the insights API) are Kubernetes manifests in ../../k8s,
# deployed by GitLab CI. Terraform owns the platform; CI owns what runs on it.

resource "google_container_cluster" "main" {
  name     = "${var.name}-gke"
  location = var.region

  enable_autopilot    = true # Google manages the nodes; we pay for what the pods use, e.g. one job per night
  deletion_protection = var.deletion_protection

  network    = var.network_id
  subnetwork = var.subnetwork_id

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  private_cluster_config {
    enable_private_nodes    = true # nodes have no public IP
    enable_private_endpoint = false
  }

  release_channel {
    channel = "REGULAR"
  }
}

resource "google_artifact_registry_repository" "images" {
  repository_id = var.name
  location      = var.region
  format        = "DOCKER"
  description   = "Container images built by GitLab CI."
}

# --- One identity per workload -------------------------------------------------------------------------------

locals {
  workloads = {
    rule-engine = {
      description = "Nightly job: reads readings, writes signals and insights."
      roles = [
        "roles/bigquery.jobUser",      # run queries
        "roles/cloudsql.client",       # connect to MySQL
        "roles/cloudsql.instanceUser", # log in to MySQL with this identity
      ]
    }
    insights-api = {
      description = "REST API for the web UI: reads and updates insights, reads data for charts."
      roles = [
        "roles/bigquery.jobUser",
        "roles/cloudsql.client",
        "roles/cloudsql.instanceUser",
      ]
    }
    history-import = {
      description = "Loads the platform's batch exports into the readings table when a building joins."
      roles = [
        "roles/bigquery.jobUser",
      ]
    }
  }

  workload_roles = flatten([
    for workload, config in local.workloads : [
      for role in config.roles : { workload = workload, role = role }
    ]
  ])
}

resource "google_service_account" "workload" {
  for_each = local.workloads

  account_id   = each.key
  display_name = each.key
  description  = each.value.description
}

resource "google_project_iam_member" "workload" {
  for_each = { for item in local.workload_roles : "${item.workload}/${item.role}" => item }

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.workload[each.value.workload].email}"
}

# Data access is granted on the dataset and bucket, not the whole project.
resource "google_bigquery_dataset_iam_member" "read_readings" {
  for_each = toset(["rule-engine", "insights-api"])

  dataset_id = var.readings_dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.workload[each.key].email}"
}

resource "google_bigquery_dataset_iam_member" "history_import_writes_readings" {
  dataset_id = var.readings_dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.workload["history-import"].email}"
}

resource "google_storage_bucket_iam_member" "history_import_reads_exports" {
  bucket = var.history_imports_bucket
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.workload["history-import"].email}"
}

# Workload Identity: the Kubernetes service account "<namespace>/<workload>" acts as the Google service account
# of the same name. No key files anywhere.
resource "google_service_account_iam_member" "workload_identity" {
  for_each = local.workloads

  service_account_id = google_service_account.workload[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.kubernetes_namespace}/${each.key}]"

  depends_on = [google_container_cluster.main] # the identity pool exists once the cluster does
}
