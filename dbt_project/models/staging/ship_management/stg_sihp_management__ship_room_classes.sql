{{
  config(
    materialized='view'
  )
}}
with source as (
  select
    trim(ship_id) as ship_id
    , trim(room_class_id) as room_class_id
    , room_count
    , capacity_per_room
    , total_occupancy
  from {{ source('ship_management_source', 'ship_room_classes') }}
)
select * from source