{{
  config(
    materialized='table'
  )
}}
with source as (
  select
    ship_id
    , room_class_id
    , room_count
    , capacity_per_room
    , total_occupancy
  from {{ source('ships_source', 'ship_room_classes') }}
)
select * from source