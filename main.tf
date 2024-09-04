provider "google" {
  project = "data-engineering-405316"
  region  = "us-west2"
}

resource "google_compute_network" "vpc_network" {
  name = "shortlet-vpc-network"
}

resource "google_compute_router" "nat_router" {
  name    = "shortlet-nat-router"
  network = google_compute_network.vpc_network.name
}

resource "google_compute_router_nat" "nat" {
  name                           = "nat-config"
  router                         = google_compute_router.nat_router.name
  nat_ip_allocate_option         = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_service_account" "gke_service_account" {
  account_id   = "gke-service-account"
  display_name = "GKE Service Account"
}

resource "google_project_iam_member" "cluster_service_account" {
  project = "data-engineering-405316"
  role   = "roles/container.admin"
  member = "serviceAccount:${google_service_account.gke_service_account.email}"
}

resource "google_container_cluster" "primary" {
  name     = "gke-cluster"
  location = "us-west2"
  initial_node_count = 1
  node_config {
    machine_type = "e2-medium"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    service_account = google_service_account.gke_service_account.email
  }

  network = google_compute_network.vpc_network.name
}

provider "kubernetes" {
  host = google_container_cluster.primary.endpoint

  client_certificate     = base64decode(google_container_cluster.primary.master_auth[0].client_certificate)
  client_key             = base64decode(google_container_cluster.primary.master_auth[0].client_key)
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = "app"
  }
}