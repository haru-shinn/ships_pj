{{
  config(
    materialized='table'
  )
}}
with source as (
  select
    schedule_id
    , section_id
    , room_class_id
    , room_count
    , remaining_room_cnt
    , num_of_people
    , remaining_num_of_people
  from {{ source('ships_source', 'inventory') }}
)
select * from source