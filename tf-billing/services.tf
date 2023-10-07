resource "google_project_service" "services" {
  for_each = toset(local.services)
  service  = each.key

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = true
}