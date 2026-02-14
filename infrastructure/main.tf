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
    "ships_stg_route_operations",
    "ships_stg_ship_management",
    "ships_stg_sales",
    "ships_int_core",
    "ships_int_inventory",
    "ships_int_sales",
    "ships_seeds_master"
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


# ----------------------------------------------------------------------
# Artifact Registry リポジトリ
# ----------------------------------------------------------------------
# dbtモデル用のリポジトリを作成
resource "google_artifact_registry_repository" "ar_repo_dbt_model" {
  repository_id = "ships-pj-dbt-model-repo-${terraform.workspace == "development" ? "dev" : "prd"}"
  description   = "Ships-pj Dev Artifact Registry for dbt model images"
  format        = "DOCKER"
  location      = "asia-northeast1"
}

# ----------------------------------------------------------------------
# Cloud Run Jobs
# ----------------------------------------------------------------------
# dbtジョブ作成
resource "google_cloud_run_v2_job" "cloud_run_job_dbt_model" {
  name                = "ships-pj-run-dbt-${terraform.workspace == "development" ? "dev" : "prd"}"
  location            = "asia-northeast1"
  project             = var.project_configs[terraform.workspace]
  deletion_protection = terraform.workspace == "development" ? false : true

  template {
    template {
      containers {
        image       = "asia-northeast1-docker.pkg.dev/${var.project_configs[terraform.workspace]}/ships-pj-dbt-model-repo-${terraform.workspace == "development" ? "dev" : "prd"}/ships-pj-run-dbt:latest"
        command     = ["/bin/sh", "-c"]
        args        = ["ls -la . && ls -la /app/dbt_project && cd /app/dbt_project && dbt deps && dbt run --target=${terraform.workspace == "development" ? "dev" : "prd"} && dbt test --target=${terraform.workspace == "development" ? "dev" : "prd"}"]
        working_dir = "/app/dbt_project"
        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }
        env {
          name  = "GCP_PROJECT_ID"
          value = var.project_configs[terraform.workspace]
        }
        env {
          name  = "DBT_PROFILES_DIR"
          value = "/app/dbt_project"
        }
      }
      max_retries     = 0
      timeout         = "300s"
      service_account = google_service_account.cloud_run_job_service_account.email
    }
  }
  lifecycle {
    ignore_changes = [template[0].template[0].containers[0].image, ]
  }
}

# ----------------------------------------------------------------------
# サービスアカウントとIAMロール設定
# ----------------------------------------------------------------------
# dbt用のサービスアカウント(Google Cloud Run Jobで利用)
resource "google_service_account" "cloud_run_job_service_account" {
  account_id   = "ships-pj-cloud-run-job-${terraform.workspace == "development" ? "dev" : "prd"}-sa"
  display_name = "ships-pj-cloud-run-job-${terraform.workspace == "development" ? "dev" : "prd"}-sa"
  description  = "Service account for cloud run job to run dbt models and transformations"
}

# BigQuery ジョブ実行用ユーザ（プロジェクトレベル）
resource "google_project_iam_member" "bq_job_user" {
  project = var.project_configs[terraform.workspace]
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.cloud_run_job_service_account.email}"
}

# BigQuery　データ編集者（データセットレベル/全データセット分に適用）
resource "google_bigquery_dataset_iam_member" "bq_data_editor" {
  for_each   = toset(local.datasets)
  dataset_id = google_bigquery_dataset.all_datasets[each.key].dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.cloud_run_job_service_account.email}"
}

# Artifact Registry 管理者
resource "google_project_iam_member" "ar_admin" {
  project = var.project_configs[terraform.workspace]
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${google_service_account.cloud_run_job_service_account.email}"
}

# Cloud Run 起動元
resource "google_project_iam_member" "cloud_run_invoker" {
  project = var.project_configs[terraform.workspace]
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.cloud_run_job_service_account.email}"
}

# Cloud Run デベロッパー
resource "google_project_iam_member" "cloud_run_developer" {
  project = var.project_configs[terraform.workspace]
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.cloud_run_job_service_account.email}"
}

# サービス アカウント ユーザー（Cloud Runを実行するのに必要）
resource "google_project_iam_member" "sa_user" {
  project = var.project_configs[terraform.workspace]
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cloud_run_job_service_account.email}"
}

# GCS フォルダ管理者
resource "google_project_iam_member" "gcs_folder_admin" {
  project = var.project_configs[terraform.workspace]
  role    = "roles/storage.folderAdmin"
  member  = "serviceAccount:${google_service_account.cloud_run_job_service_account.email}"
}

# ログ閲覧者
resource "google_project_iam_member" "logging_viewer" {
  project = var.project_configs[terraform.workspace]
  role    = "roles/logging.viewer"
  member  = "serviceAccount:${google_service_account.cloud_run_job_service_account.email}"
}

# BigQuery データセット作成者
resource "google_project_iam_member" "cloud_run_job_bq_user" {
  project = var.project_configs[terraform.workspace]
  role    = "roles/bigquery.user"
  member  = "serviceAccount:${google_service_account.cloud_run_job_service_account.email}"
}
