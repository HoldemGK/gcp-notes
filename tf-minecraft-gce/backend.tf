terraform {
  cloud {
    organization = "gkllc"

    workspaces {
      name = "tf-minecraft-gce"
    }
  }
}