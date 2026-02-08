# 環境構築ログ

## ETL (dbt)

```bash
# 初期化（コンテナ内で実行）
dbt init dbt_project

# profiles.ymlは他の場所から /app/dbt_project/ へ移動する。
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
