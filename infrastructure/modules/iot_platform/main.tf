# PLACEHOLDER MODULE - the IoT data platform is not ours to manage.
#
# Role: delivers building data in two ways:
#   - write events: one JSON message per new reading, published to a Pub/Sub topic owned by the platform.
#   - batch exports: historic data, used once when a building joins (history run).
#
# Interface we rely on:
#   - The topic id, e.g. projects/iot-platform/topics/sensor-readings.
#   - Our project may attach a subscription to that topic (the platform grants
#     roles/pubsub.subscriber, or pubsub.topics.attachSubscription, to our project).
#   - Batch exports are delivered as files into the import bucket we provide (module "storage").
#   - The list of equipment with its tagged sensors (assumption A3), synced into MySQL by the engine.
#
# This module creates nothing. It only makes the dependency explicit, so the rest of the code
# refers to "the platform" instead of to loose strings.
