provider "google" {
  project = "project-id"
  region  = var.region
  zone    = var.zone
}

resource "google_container_cluster" "primary" {
  name                     = "my-gke-cluster"
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-medium"
  }
}