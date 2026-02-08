# ==========================================================
# ステージ 1: ビルダー (Build Stage)
# ==========================================================
FROM python:3.12-slim AS builder

ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ==========================================================
# ステージ 2: 開発環境 (Development Stage - Dev Containers用)
# ==========================================================
FROM python:3.12-slim AS development

ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 TZ=Asia/Tokyo \
    DBT_PROFILES_DIR=/app/dbt_project

WORKDIR /app

# 開発に必要なツールをすべて入れる
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git ssh-client curl ca-certificates gnupg vim \
    && rm -rf /var/lib/apt/lists/*

# gcloud CLI のインストール
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update && apt-get install -y google-cloud-sdk && rm -rf /var/lib/apt/lists/*

# Terraform のインストール
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com bookworm main" > /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update && apt-get install -y terraform \
    && rm -rf /var/lib/apt/lists/*

# ビルダーからライブラリをコピー
COPY --from=builder /install /usr/local

# 開発時は root で作業することが多いですが、必要に応じてユーザー切り替えも可能
CMD ["bash"]

# ==========================================================
# ステージ 3: 実行環境 (Final Stage - 本番デプロイ用)
# ==========================================================
FROM python:3.12-slim AS production

ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 TZ=Asia/Tokyo \
    DBT_PROFILES_DIR=/app/.dbt

WORKDIR /app/dbt_project

# 本番に必要な最小限のツール（gcloud等）
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates gnupg \
    && rm -rf /var/lib/apt/lists/*

# gcloud CLI (本番の認証にも必要)
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update && apt-get install -y google-cloud-sdk && rm -rf /var/lib/apt/lists/*

RUN groupadd -r app && useradd -r -g app app \
    && mkdir -p /app/.dbt /app/dbt_project && chown -R app:app /app

# ビルダーからライブラリをコピー
COPY --from=builder /install /usr/local

USER app
# 本番用ファイルのコピー（CI/CDビルド時に実行される）
# COPY --chown=app:app . .