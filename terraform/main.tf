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
  project = var.project_id
  region = var.region
  database_version = "POSTGRES_13"
  settings {
    tier = "db-f1-micro"
  }
}

resource "random_password" "postgres_password" {
  length           = 32
  special          = true
}

resource "google_sql_user" "postgres_user" {
  name     = var.postgres_user
  instance = google_sql_database_instance.postgres.name
  password = random_password.postgres_password.result
}

module "gke_auth" {
  source               = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  project_id           = "my-project-id"
  cluster_name         = "my-cluster-name"
  location             = module.gke.location
  use_private_endpoint = true
}

provider "kubernetes" {
  cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
  host                   = module.gke_auth.host
  token                  = module.gke_auth.token
}

resource "kubernetes_secret" "postgres_credentials" {
  metadata {
    name = "postgres_credentials"
  }

  data = {
    username = google_sql_user.postgres_user.name
    password = google_sql_user.postgres_user.password
  }

  type = "kubernetes.io/basic-auth"
}