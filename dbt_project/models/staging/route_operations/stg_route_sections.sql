{{
  config(
    materialized='table'
  )
}}
with source as (
  select
    section_id
    , route_id
  from {{ source('ships_source', 'route_sections') }}
)
select * from source