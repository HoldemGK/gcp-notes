resource "google_project_service" "enable_bq_api" {
  for_each                   = toset(var.services)
  project                    = var.project
  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false
}