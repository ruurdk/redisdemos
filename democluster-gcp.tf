variable "boot_disk_size" {}
variable "boot_disk_image" {}
variable "machine_type" {}
variable "machine_base_name" {}
variable "network_base_name" {}
variable "gce_ssh_user" {}
variable "gce_ssh_pub_key_file" {}
variable "cluster_name" {}
variable "dns_base" {}
variable "managed_zone" {}

provider "google" {
  project = "central-beach-194106"
  region  = "europe-west4"
  zone    = "europe-west4-a"
}

// Machines

resource "google_compute_instance" "vm_instance-1" {
  name         = "${var.machine_base_name}-vm1"
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = var.boot_disk_image
      size = var.boot_disk_size
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = google_compute_network.vpc_network.self_link
    access_config {
    }
  }

  metadata = {
      enable-oslogin = "false"
      ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }
  
  tags = ["http-server", "https-server"]
}

resource "google_compute_instance" "vm_instance-2" {
  name         = "${var.machine_base_name}-vm2"
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = var.boot_disk_image
      size = var.boot_disk_size
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = google_compute_network.vpc_network.self_link
    access_config {
    }
  }

   metadata = {
      enable-oslogin = "false"
      ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  } 

  tags = ["http-server", "https-server"]
}

resource "google_compute_instance" "vm_instance-3" {
  name         = "${var.machine_base_name}-vm3"
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = var.boot_disk_image
      size = var.boot_disk_size
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = google_compute_network.vpc_network.self_link
    access_config {
    }
  }

  metadata = {
      enable-oslogin = "false"
      ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  tags = ["http-server", "https-server"]
}

resource "google_compute_instance" "vm_instance-client" {
  name         = "${var.machine_base_name}-client"
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = var.boot_disk_image
      size = var.boot_disk_size
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = google_compute_network.vpc_network.self_link
    access_config {
    }
  }

  metadata = {
      enable-oslogin = "false"
      ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  tags = ["http-server", "https-server"]
}

// Networking

resource "google_compute_network" "vpc_network" {
  name                    = "${var.network_base_name}-vpc"
  auto_create_subnetworks = "true"
}

resource "google_compute_firewall" "firewall" {
    name = "${var.network_base_name}-firewall"
    network = google_compute_network.vpc_network.self_link

    allow {
        protocol = "icmp"
    }

    allow {
        protocol = "tcp"
        ports = ["80", "443", "22", "53", "1000-30000"]
    }

    allow {
        protocol = "udp"
        ports = ["53"]
    }

    source_ranges = ["0.0.0.0/0"]
}

// DNS setup

resource "google_dns_record_set" "ns1" {
    name = "ns1.${var.cluster_name}.${var.dns_base}."
    type = "A"
    ttl = 300

    managed_zone = var.managed_zone
    rrdatas = [google_compute_instance.vm_instance-1.network_interface[0].access_config[0].nat_ip]
}

resource "google_dns_record_set" "ns2" {
    name = "ns2.${var.cluster_name}.${var.dns_base}."
    type = "A"
    ttl = 300

    managed_zone = var.managed_zone
    rrdatas = [google_compute_instance.vm_instance-2.network_interface[0].access_config[0].nat_ip]
}

resource "google_dns_record_set" "ns3" {
    name = "ns3.${var.cluster_name}.${var.dns_base}."
    type = "A"
    ttl = 300

    managed_zone = var.managed_zone
    rrdatas = [google_compute_instance.vm_instance-3.network_interface[0].access_config[0].nat_ip]
}

resource "google_dns_record_set" "clusterdns" {
    name = "${var.cluster_name}.${var.dns_base}."
    type = "NS"
    ttl = 300

    managed_zone = var.managed_zone
    rrdatas = [ "ns1.${var.cluster_name}.${var.dns_base}.", "ns2.${var.cluster_name}.${var.dns_base}.", "ns3.${var.cluster_name}.${var.dns_base}." ]
}

output "cluster_ips" {
    value = [
        google_compute_instance.vm_instance-1.network_interface[0].access_config[0].nat_ip,
        google_compute_instance.vm_instance-2.network_interface[0].access_config[0].nat_ip,
        google_compute_instance.vm_instance-3.network_interface[0].access_config[0].nat_ip,
    ]
}
output "master_internal_ip" {
    value = google_compute_instance.vm_instance-1.network_interface[0].network_ip
}

output "client_ip" {
    value = google_compute_instance.vm_instance-client.network_interface[0].access_config[0].nat_ip
}
output "clustername" {
    value = trim(google_dns_record_set.clusterdns.name, ".")
}