{{
  config(
    materialized='table'
  )
}}
with source as (
  select
    schedule_id
    , route_id
    , section_id
    , departure_time
    , arrival_time
    , ship_id
  from {{ source('ships_source', 'schedule') }}
)
select * from source