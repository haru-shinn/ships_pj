import os
from pathlib import Path
from dagster import Definitions, asset
from dagster_dbt import DbtCliResource, dbt_assets


# プロジェクトルートからの dbt_project へのパス
DBT_PROJECT_DIR = Path(__file__).joinpath("..", "..", "dbt_project").resolve()

# dbtをアセットとして定義
@dbt_assets(manifest=DBT_PROJECT_DIR / "target/manifest.json")
def my_dbt_assets(context, dbt: DbtCliResource):
    yield from dbt.cli(["run"], context=context).stream()

# Pythonでのデータ処理（Rawデータ挿入を想定）の練習用アセット
@asset
def simple_python_asset():
    return "Hello Dagster!"

# 全体の定義
defs = Definitions(
    assets=[my_dbt_assets, simple_python_asset],
    resources={
        "dbt": DbtCliResource(project_dir=os.fspath(DBT_PROJECT_DIR)),
    },
)