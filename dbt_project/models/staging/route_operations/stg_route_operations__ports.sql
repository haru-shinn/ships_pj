{{
  config(
    materialized='view'
  )
}}
with source as (
  select
    trim(port_id) as port_id
    , port_name
  from {{ source('route_operations_source', 'ports') }}
)
select * from source