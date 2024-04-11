provider "google" {
  project = "${var.project_id}"
  region = "${var.region}"
  zone = "${var.zone}"
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
  
}

terraform {
  backend "local" {
    path = "terraform/state/terraform.tfstate"
  }
}

terraform {
  backend "gcs" {
    bucket = "${google_storage_bucket.storage-backet-backend-state.name}"
  }
}

module "vpn-module" {
  source = "terraform-google-modules/network/google"
  version = "~> 6.0"
  project_id = var.project_id
  network_name = var.network_name
  mtu = 1460

  subnets = [
    {
      subnet_name   = "subnet-01"
      subnet_ip     = "10.10.10.0/24"
      subnet_region = var.region
    }
  ]
}