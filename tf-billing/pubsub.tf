resource "google_pubsub_topic" "bill_alert" {
  name = "bill-alert"

  labels = {
    cost = "controle"
  }
}