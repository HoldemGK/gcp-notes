resource "google_pubsub_topic" "bill_alert" {
  name = "bill-alert"

  labels = {
    cost = "controle"
  }
  depends_on = [ google_project_service.services ]
}