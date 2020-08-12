output "endpoint" {
  value = google_sql_database_instance.sql_jira_inst.connection_name
}

output "root_password" {
  value       = coalesce(var.root_password, random_password.root-password.result)
  sensitive   = true
}

# Return service Cloud Run URL
output "url" {
  value = "${google_cloud_run_service.jira-crun.status[0].url}"
}
