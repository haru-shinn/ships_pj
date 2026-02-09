{{
  config(
    materialized='table'
  )
}}
with source as (
  select
    route_id
    , departure_port_id
    , arrival_port_id
  from {{ source('ships_source', 'routes') }}
)
select * from source