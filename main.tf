module "network" {
  source  = "terraform-google-modules/network/google"
  version = "9.1.0"
  network_name = "my-vpc-network"
  project_id   = var.project

  subnets = [
    {
      subnet_name   = "subnet-01"
      subnet_ip     = var.cidr
      subnet_region = var.region
    },
  ]

  secondary_ranges = {
    subnet-01 = []
  }
}

module "network_routes" {
  source  = "terraform-google-modules/network/google//modules/routes"
  version = "9.1.0"
  network_name = module.network.network_name
  project_id   = var.project

   routes = [
         {
             name                   = "egress-internet"
             description            = "route through IGW to access internet"
             destination_range      = "0.0.0.0/0"
             tags                   = "egress-inet"
             next_hop_internet      = "true"
         },

     ]
}
module "network_fabric-net-firewall" {
  source  = "terraform-google-modules/network/google//modules/fabric-net-firewall"
  version = "9.1.0"
  project_id              = var.project
  network                 = module.network.network_name
  internal_ranges_enabled = true
  internal_ranges         = ["10.0.0.0/16"]

}

resource "google_compute_instance" "vm_instance" {
  name = "mtnewvm-test"
  metadata_startup_script = file("startup.sh")
  machine_type = "f1-micro"
  tags = ["web"]
  zone = "us-central1-a"
  boot_disk {
    initialize_params {
      image = "ubuntu-2004-lts"
    }
  }

  network_interface {
     network = "projects/kubernetes-prj-378217/global/networks/my-vpc-network"
     subnetwork = "projects/kubernetes-prj-378217/regions/us-central1/subnetworks/subnet-01"
    access_config {
    }
  }
}

resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network = "my-vpc-network"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "1000-2000"]
  }

  target_tags = ["web"]
  source_ranges = ["0.0.0.0/0"]
}
