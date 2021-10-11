provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_service_account" "default" {
  account_id   = "k8s-service-account-id"
  display_name = "K8s Service Account"
}

resource "google_project_iam_member" "registry_reader_binding" {
  role    = "roles/containerregistry.ServiceAgent"
  member  = "serviceAccount:${google_service_account.default.email}"
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

    service_account = google_service_account.default.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

resource "google_sql_database_instance" "postgres" {
  name = "postgres"
  project_id = var.project_id
  zone = var.zone
  database_version = "POSTGRES_13"
}
