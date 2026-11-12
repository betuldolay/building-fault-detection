# write events -> BigQuery, with no code of ours to run.
#
# A BigQuery subscription on the platform's topic writes each message straight into the readings table.
# One small transform runs first: the event's "value" is a number or a boolean, and a BigQuery column has one type,
# so it is moved into value_number or value_bool. Messages that cannot be written end up in a dead-letter topic
# instead of blocking the rest.

data "google_project" "this" {
  project_id = var.project_id
}

locals {
  # Google's own service agent that delivers Pub/Sub messages.
  pubsub_service_agent = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_subscription" "readings_to_bigquery" {
  name  = "readings-to-bigquery"
  topic = var.readings_topic_id

  bigquery_config {
    table               = var.readings_table_id
    use_table_schema    = true # JSON fields map to columns with the same name
    drop_unknown_fields = true # extra fields the platform may add later do not stop ingestion
  }

  message_transforms {
    javascript_udf {
      function_name = "splitValue"
      code          = <<-EOT
        // The write event has "value": number | boolean; the readings table has value_number and value_bool.
        function splitValue(message, metadata) {
          const reading = JSON.parse(message.data);

          if (typeof reading.value === "number") {
            reading.value_number = reading.value;
          } else if (typeof reading.value === "boolean") {
            reading.value_bool = reading.value;
          } else {
            // Unexpected value: fail, so the message goes to the dead-letter topic instead of being stored wrongly.
            throw new Error("value must be a number or a boolean");
          }
          delete reading.value;

          message.data = JSON.stringify(reading);
          return message;
        }
      EOT
    }
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = 10
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  # If BigQuery is unavailable, messages wait here (up to 7 days) and are delivered later.
  message_retention_duration = "604800s"

  depends_on = [google_bigquery_dataset_iam_member.pubsub_writes_readings]
}

resource "google_bigquery_dataset_iam_member" "pubsub_writes_readings" {
  dataset_id = var.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = local.pubsub_service_agent
}

# Dead letters: kept for two weeks so someone can look at what went wrong and replay it.
resource "google_pubsub_topic" "dead_letter" {
  name = "readings-dead-letter"
}

resource "google_pubsub_subscription" "dead_letter_inspection" {
  name                       = "readings-dead-letter-inspection"
  topic                      = google_pubsub_topic.dead_letter.id
  message_retention_duration = "1209600s"
}

resource "google_pubsub_topic_iam_member" "pubsub_publishes_dead_letters" {
  topic  = google_pubsub_topic.dead_letter.id
  role   = "roles/pubsub.publisher"
  member = local.pubsub_service_agent
}

resource "google_pubsub_subscription_iam_member" "pubsub_forwards_dead_letters" {
  subscription = google_pubsub_subscription.readings_to_bigquery.id
  role         = "roles/pubsub.subscriber"
  member       = local.pubsub_service_agent
}
