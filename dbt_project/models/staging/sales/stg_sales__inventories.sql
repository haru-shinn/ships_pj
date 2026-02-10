{{
  config(
    materialized='view'
  )
}}
with source as (
  select
    trim(schedule_id) as schedule_id
    , trim(section_id) as section_id
    , trim(room_class_id) as room_class_id
    , room_count
    , remaining_room_cnt
    , num_of_people
    , remaining_num_of_people
  from {{ source('sales_source', 'inventories') }}
)
select * from source