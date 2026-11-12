# MySQL (Cloud SQL): equipment list, signals, insights, assignments, audit log.
# Private IP only, and no passwords: workloads log in with their own service account (IAM database authentication).

resource "google_sql_database_instance" "main" {
  name                = "${var.name}-mysql"
  region              = var.region
  database_version    = "MYSQL_8_4"
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    edition           = "ENTERPRISE"
    availability_type = var.availability_type

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_id
    }

    backup_configuration {
      enabled            = true
      binary_log_enabled = true # point-in-time recovery
    }

    database_flags {
      name  = "cloudsql_iam_authentication"
      value = "on"
    }
  }

  depends_on = [var.private_services_connection]
}

resource "google_sql_database" "insights" {
  name     = "insights"
  instance = google_sql_database_instance.main.name
}

# One database user per workload, backed by its service account. Rights inside MySQL (which tables) are granted
# by the schema migrations, not here.
resource "google_sql_user" "workload" {
  for_each = var.workload_service_accounts

  name     = each.value
  instance = google_sql_database_instance.main.name
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}
