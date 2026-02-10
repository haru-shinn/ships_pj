{{
  config(
    materialized='view'
  )
}}
with source as (
  select
    trim(room_class_id) as room_class_id
    , room_class_name
    , capacity_per_room
    , description
  from {{ source('ship_management_source', 'room_class_masters') }}
)
select * from source