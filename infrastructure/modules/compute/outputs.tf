output "cluster_name" {
  value = google_container_cluster.main.name
}

output "image_repository" {
  description = "Where GitLab CI pushes images, e.g. europe-west4-docker.pkg.dev/project/fault-detection."
  value       = "${google_artifact_registry_repository.images.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.images.repository_id}"
}

output "workload_service_accounts" {
  description = "Google service account email per workload."
  value       = { for name, account in google_service_account.workload : name => account.email }
}
