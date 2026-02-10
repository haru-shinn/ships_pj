{{
  config(
    materialized='view'
  )
}}
with source as (
  select
    trim(route_id) as route_id
    , trim(departure_port_id) as departure_port_id
    , trim(arrival_port_id) as arrival_port_id
  from {{ source('route_operations_source', 'routes') }}
)
select * from source