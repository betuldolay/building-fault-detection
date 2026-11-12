# Infrastructure

The GCP infrastructure of the Building Fault Detection design, in Terraform. It describes the architecture in section
5 of [the design document](../design-document.md). It hasn't been deployed: it shows how the design translates into
infrastructure-as-code, not a production-ready setup.

## What is where

```
IoT platform ──readings─► Pub/Sub ──BigQuery subscription──► BigQuery: readings          ingestion, storage
             ──batch exports──► Cloud Storage ──load job───────────┘                     storage
                                                                   │
                     GKE Autopilot: nightly rule-engine job ───────┤ reads              compute, k8s/
                                                                   ▼
                     Cloud SQL (MySQL), private IP: signals, insights                    database
```

| Module | Creates | Design document |
|---|---|---|
| `iot_platform` | nothing: a **placeholder** that describes what the platform provides (its topic, batch exports, equipment list) | A3 |
| `network` | private VPC, subnet for the cluster, private access for MySQL | security |
| `storage` | BigQuery dataset and `readings` table (partitioned by day, clustered by building); bucket for history imports | section 6 |
| `ingestion` | BigQuery subscription on the platform's topic, a small message transform, dead-letter topic | section 6 |
| `database` | Cloud SQL MySQL 8.4, private IP, backups, a database user per workload | section 6 |
| `compute` | GKE Autopilot cluster, image registry, one service account per workload with minimal rights | 7.4, 10 |

`environments/dev` puts the modules together. A `prod` environment would be the same file with other values
(e.g. high-availability MySQL), and only that.

`k8s/rule-engine-cronjob.yaml` is the nightly job: 02:00 Amsterdam time, never two runs at once, retried on
failure. Terraform owns the platform, and **GitLab CI deploys what runs on it**. Releasing a new rule changes the
image, never the Terraform.

## Choices worth explaining

- **Ingestion without code.** A BigQuery subscription writes each message straight into the table, so there's no
  service of ours to run or keep alive. If BigQuery is unavailable, messages wait in Pub/Sub for up to 7 days.
- **The transform.** The event's `value` is `number | boolean`, but a BigQuery column has one type.
  A small script in the [`ingestion` module](modules/ingestion/main.tf) moves it into `value_number` or
  `value_bool`. All other field names stay exactly as in the platform's event, so the subscription can match them
  to columns.
- **Bad messages don't block good ones.** A message that can't be written goes to a dead-letter topic after
  10 attempts, and is kept 2 weeks to inspect and replay.
- **Partitioning and clustering** make "one building, last 7 days" read about 8 days of one building, not years
  of everything. `require_partition_filter` makes a query without a time filter fail instead of costing a lot.
- **No passwords or key files.** Workloads use Workload Identity to act as their own Google service account, and
  log in to MySQL with that same identity (IAM database authentication). The nodes and the database have no public IP.
- **Least privilege.** The rule engine can read readings, not change them. Only the history import can write
  readings, and only it can read the import bucket.
- **Autopilot.** For one job per night plus a small API, managing nodes is wasted effort. We pay for what pods use.
- **Splitting over pods** is a number in the CronJob (`completions`), not new infrastructure.
- **`deletion_protection`** is on by default for the table, the cluster and MySQL. Only a throw-away dev
  environment turns it off.

## Assumptions and things to check before a real deployment

- **The platform's topic.** The platform publishes write events to a topic it owns, and lets our project attach
  a subscription.
- **Message format.** I checked Google's documentation for the BigQuery subscription's table schema: it documents
  converting a JSON string to `TIMESTAMP`. Writing JSON numbers into `FLOAT64`, booleans into `BOOL` and the
  `tags` array into a repeated column is what I'd expect, but I didn't find it stated explicitly. I'd confirm
  it with one test message before going further.
- **Duplicates.** Pub/Sub can deliver a message twice, so the table can contain a reading twice. The rule engine
  isn't affected by this (see section 6 of the design), so there's no deduplication step.
- **Left out on purpose:** monitoring and alerting (a failed nightly run, a building that stops sending data), the
  insights API's deployment, the GitLab CI pipeline, and remote state. Each one is a small addition, and they're
  named in the design's operations section.

## Try it

No GCP account is needed to check the code:

```bash
cd environments/dev
terraform init -backend=false
terraform validate
```
