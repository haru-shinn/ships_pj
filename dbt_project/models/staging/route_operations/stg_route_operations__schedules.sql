{{
  config(
    materialized='view'
  )
}}
with source as (
  select
    trim(schedule_id) as schedule_id
    , trim(route_id) as route_id
    , trim(section_id) as section_id
    , cast(departure_time as datetime) as departure_time
    , cast(arrival_time as datetime) as arrival_time
    , trim(ship_id) as ship_id
  from {{ source('route_operations_source', 'schedules') }}
)
select * from source