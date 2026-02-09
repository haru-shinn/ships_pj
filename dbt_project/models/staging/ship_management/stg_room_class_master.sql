{{
  config(
    materialized='table'
  )
}}
with source as (
  select
    room_class_id
    , room_class_name
    , capacity_per_room
    , notice
  from {{ source('ships_source', 'room_class_master') }}
)
select * from source