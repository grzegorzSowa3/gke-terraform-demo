variable "project_id" {
  type = string
}

variable "region" {
  type = string
  default = "europe-central2"
}

variable "zone" {
  type = string
  default = "europe-central2-a"
}

variable "postgres_user" {
  type = string
  default = "user"
}