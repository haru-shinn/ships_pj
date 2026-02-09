{{
  config(
    materialized='table'
  )
}}
with source as (
  select
    section_id
    , departure_port_id
    , arrival_port_id
    , travel_time_minutes
  from {{ source('ships_source', 'sections') }}
)
select * from source