locals {
  dataset_name = element(
    concat(google_bigquery_dataset.dataset.*.dataset_id, [""]),
    0,
  )
  destination_uri = "bigquery.googleapis.com/projects/${var.project}/datasets/${local.dataset_name}"
}