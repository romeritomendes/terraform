resource "google_compute_instance" "myfirst-resource-terraform" {
  project      = "<PROJECT_ID>"
  name         = "terraform"
  machine_type = "e2-medium"
  zone         = "<ZONE>"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    access_config {
    }
  }
}