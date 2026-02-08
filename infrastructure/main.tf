# ----------------------------------------------------------------------
# Terraform 設定ブロック
# ----------------------------------------------------------------------
terraform {
  required_version = ">= 1.6.0"
  backend "gcs" {
    prefix = "terraform/state"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}


# ----------------------------------------------------------------------
# Google Cloud Provider 設定
# ----------------------------------------------------------------------
provider "google" {
  # プロジェクトIDとリージョンは variables.tf で定義した変数で設定
  project = var.project_configs[terraform.workspace]
  region  = "asia-northeast1"
}


# ----------------------------------------------------------------------
# BigQuery データセット
# ----------------------------------------------------------------------
locals {
  datasets = [
    "ships_raw",
    "ships_staging",
    "ships_intermediate",
    "ships_mart",
  ]
}

resource "google_bigquery_dataset" "all_datasets" {
  for_each    = toset(local.datasets)
  dataset_id  = terraform.workspace == "development" ? "${each.key}_dev" : "${each.key}"
  location    = "asia-northeast1"
  description = "ships_pj_${terraform.workspace == "development" ? "開発用" : "本番用"}"
}

# ----------------------------------------------------------------------
# Cloud Storage バケット
# ----------------------------------------------------------------------
# データレイク用バケット（フォルダはIaC化せずにGUIやCLIで作成する）
resource "google_storage_bucket" "storage_bucket_data_lake" {
  name                     = "ships-pj-bucket-${terraform.workspace == "development" ? "dev" : "prd"}"
  location                 = "asia-northeast1"
  force_destroy            = false
  public_access_prevention = "enforced"
}
