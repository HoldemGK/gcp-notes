provider "google" {
  credentials = "${file("credentials.json")}"
  project     = "indigo-lambda-249413"
  region      = "europe-north1"
}

module "web-serv" {
  source = "./modules"
  hostname   = "web-serv-test"
}
