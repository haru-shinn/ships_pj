{{
  config(
    materialized='table'
  )
}}
with source as (
  select * from {{ source('ships_source', 'ships') }}
)
select * from source