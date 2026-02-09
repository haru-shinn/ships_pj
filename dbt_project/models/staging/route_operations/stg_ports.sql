{{
  config(
    materialized='table'
  )
}}
with source as (
  select
    port_id
    , port_name
  from {{ source('ships_source', 'ports') }}
)
select * from source