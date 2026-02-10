{{
  config(
    materialized='view'
  )
}}
with source as (
  select
    trim(section_id) as section_id
    , route_id
  from {{ source('route_operations_source', 'route_sections') }}
)
select * from source