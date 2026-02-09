{{
  config(
    materialized='table'
  )
}}
with source as (
  select
    reservation_id
    , detail_id
    , section_id
    , schedule_id
    , passenger_id
    , passenger_type
    , ship_id
    , room_class_id
    , applied_fare
  from {{ source('ships_source', 'reservation_details') }}
)
select * from source