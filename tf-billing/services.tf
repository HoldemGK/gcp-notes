resource "google_project_service" "services" {
  for_each = toset(local.services)
  service  = each.key

  disable_dependent_services = true
}