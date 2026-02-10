# 環境構築ログ

## ETL (dbt)

```bash
# 初期化（コンテナ内で実行）
dbt init dbt_project

# profiles.ymlは他の場所から /app/dbt_project/ へ移動する。

# 接続テスト
dbt debug --target=dev

# コンパイルチェック
dbt compile --target=dev

# yamlファイル作成の自動化
# packages.ymlに dbt-labs/codegen を追加して、dbt deps
# dbt run でテーブルを作成した状態で下記を実行
dbt run-operation generate_model_yaml --args '{"model_names": ["stg_ports", "stg_routes", "stg_sections", "stg_route_sections", "stg_schedule"]}' --target=dev
dbt run-operation generate_model_yaml --args '{"model_names": ["stg_ships", "stg_room_class_master", "stg_ship_room_classes"]}' --target=dev
dbt run-operation generate_model_yaml --args '{"model_names": ["stg_reservations", "stg_reservation_details", "stg_inventory"]}' --target=dev

# dbt run (select利用)
dbt run --target=dev --select models/staging/route_operations
dbt run --target=dev --select models/staging/sales
dbt run --target=dev --select models/staging/ship_management
```

## IaC (Teffaform)

```bash
# 初期化（stateファイルを開発と本番で分離、Cloud Storageに保管している）
terraform init -backend-config="bucket=ships-pj-bucket-dev" -reconfigure
terraform init -backend-config="bucket=ships-pj-bucket-prd" -reconfigure

# ワークスペース（defaultは利用しない）
terraform workspace new development
terraform workspace new production

terraform workspace list
terraform workspace select development
terraform workspace select production

# インポート
terraform import google_storage_bucket.storage_bucket_data_lake ships-pj-bucket-dev
terraform import google_storage_bucket.storage_bucket_data_lake ships-pj-bucket-prd

# planチェック
terraform plan

# 適用
terraform apply
```

## CI/CD (GitHub Actions)

```bash

```

## オーケストレーション (dagster)

```bash

```
