output "endpoint" {
  value = "${google_sql_database_instance.sql_jira_inst.connection_name}"
}
