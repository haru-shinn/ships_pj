{{
  config(
    materialized='view'
  )
}}
with source as (
  select
    trim(section_id) as section_id
    , trim(departure_port_id) as departure_port_id
    , trim(arrival_port_id) as arrival_port_id
    , travel_time_minutes
  from {{ source('route_operations_source', 'sections') }}
)
select * from source