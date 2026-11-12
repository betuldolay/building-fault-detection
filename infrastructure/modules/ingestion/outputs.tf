output "subscription_id" {
  value = google_pubsub_subscription.readings_to_bigquery.id
}

output "dead_letter_topic_id" {
  value = google_pubsub_topic.dead_letter.id
}
