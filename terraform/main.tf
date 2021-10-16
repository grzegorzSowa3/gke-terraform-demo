terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.88.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.5.1"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

data "google_client_config" "default" {}

resource "google_service_account" "default" {
  account_id   = "k8s-service-account-id"
  display_name = "K8s Service Account"
}

resource "google_project_iam_member" "registry_reader_binding" {
  role   = "roles/containerregistry.ServiceAgent"
  member = "serviceAccount:${google_service_account.default.email}"
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

resource "random_string" "postgres_name" {
  length = 6
  special = false
  upper = false
}

resource "google_sql_database_instance" "postgres" {
  name             = format("postgres%s", random_string.postgres_name.result)
  project          = var.project_id
  region           = var.region
  database_version = "POSTGRES_13"
  settings {
    tier = "db-f1-micro"
  }
  deletion_protection = false #TODO: true in real application
}

resource "random_password" "postgres_password" {
  length  = 32
  special = true
}

resource "google_sql_user" "postgres_user" {
  name     = var.postgres_user
  instance = google_sql_database_instance.postgres.name
  password = random_password.postgres_password.result
}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

resource "kubernetes_secret" "postgres_credentials" {
  metadata {
    name = "postgres-credentials"
  }

  data = {
    host = google_sql_database_instance.postgres.first_ip_address
    username = google_sql_user.postgres_user.name
    password = google_sql_user.postgres_user.password
  }

  type = "kubernetes.io/basic-auth"
}