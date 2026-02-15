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

## Google Cloud

```bash
# Artifact Registryへの認証（初回のみ）
gcloud auth configure-docker asia-northeast1-docker.pkg.dev

# イメージのビルド（マルチプラットフォーム対応に注意）
docker build -t ships-pj-run-dbt:latest .
docker tag ships-pj-run-dbt:latest asia-northeast1-docker.pkg.dev/<PROJECT_ID>/ships-pj-dbt-model-repo-dev/ships-pj-run-dbt:latest
docker run --rm <ビルドしたイメージ名> ls -R /app

# Artifact RegistryへのPush
docker push asia-northeast1-docker.pkg.dev/<PROJECT_ID>/ships-pj-dbt-model-repo-dev/ships-pj-run-dbt:latest

# Cloud Run Jobs の実行
gcloud config configurations list
gcloud config configurations activate default
gcloud run jobs execute ships-pj-run-dbt-dev --region=asia-northeast1

# ----------------------------------------------- #
# BigQuery上の資材削除
bq ls --format=sparse | grep "ships_"
for ds in $(bq ls --format=sparse | grep "ships_"); do
  bq rm -r -f -d "$ds"
done
```


## CI/CD (GitHub Actions)

```bash
- dbtのCI/CD化 失敗している。。
　- 現状: 最新イメージを直接プッシュ＋手動実行で成功。中身（profiles.yml や models）は正しいことは確認済み。
　- 残りの課題: GitHub Actions (cicd.yml) 経由で、イメージ更新とコマンド（args）設定を完全に同期させること。
```

## オーケストレーション (dagster)

```bash
# 構築
# 手動でファイルを配置した。

# 実行
dagster dev
```

## その他

- 2026/02/15 
  - CI/CDはできていないが、IaCとdagster を試すことはできた。
  - Cloud Run Jobs など、クラウド環境の整備などが大変である。
  - dbt以外のツールのお試しができたため、本PJは終了する。
  - dbtでの追加のマート作成などの設計や考え方の学習は別のPJで行う。