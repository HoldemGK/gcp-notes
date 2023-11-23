resource "random_id" "deployment_id" {
  byte_length = 4
}

# Create a Cloud Storage bucket for ingesting external log data to transfer to BigQuery
resource "google_storage_bucket" "ingest_bucket" {
  name     = "${replace(var.prefix, "_", "-")}-ingest-${random_id.deployment_id.hex}"
  location = var.region
  labels   = var.labels

  uniform_bucket_level_access = true
}

# Project-level
resource "google_logging_project_sink" "sink" {
  name                   = "${var.prefix}_logsink_${random_id.deployment_id.hex}"
  filter                 = "resource.type=${var.filter_resource}"
  destination            = local.destination_uri
  unique_writer_identity = true
  bigquery_options {
    use_partitioned_tables = true
  }
}

# Bigquery dataset #
resource "google_bigquery_dataset" "dataset" {
  dataset_id                      = "${replace(var.prefix, "-", "_")}_dataset_sink_${random_id.deployment_id.hex}"
  location                        = var.region
  delete_contents_on_destroy      = var.delete_contents_on_destroy
}

resource "google_bigquery_table" "bigquery_data_transfer_destination" {
  depends_on = [
    google_bigquery_dataset.dataset
  ]
  dataset_id          = local.dataset_name
  table_id            = "transferred_logs"
  labels              = var.labels
  deletion_protection = false
}

# Create a BigQuery Data Transfer Service job to ingest data on Cloud Storage to Biguquery
resource "google_bigquery_data_transfer_config" "log_transfer" {
  depends_on = [
    google_bigquery_dataset.dataset,
    google_bigquery_table.bigquery_data_transfer_destination
  ]
  display_name           = "Log ingestion from GCS to BQ"
  location               = var.region
  data_source_id         = "google_cloud_storage"
  schedule               = "every 15 minutes"
  destination_dataset_id = local.dataset_name
  service_account_name   = "terraform@${var.project}.iam.gserviceaccount.com"
  params = {
    data_path_template              = "gs://${resource.google_storage_bucket.ingest_bucket.name}/*.json"
    destination_table_name_template = google_bigquery_table.bigquery_data_transfer_destination.table_id
    file_format                     = "JSON"
  }
}