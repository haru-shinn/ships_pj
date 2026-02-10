{{
  config(
    materialized='view'
  )
}}
with source as (
  select
    trim(reservation_id) as reservation_id
    , trim(detail_id) as detail_id
    , trim(section_id) as section_id
    , trim(schedule_id) as schedule_id
    , trim(passenger_id) as passenger_id
    , passenger_type
    , case
        when passenger_type = 'ADULT' then '2'
        when passenger_type = 'CHILD' then '1'
        when passenger_type = 'INFANT' then '0'
        else '99' 
      end as passenger_type_code
    , trim(ship_id) as ship_id
    , trim(room_class_id) as room_class_id
    , cast(applied_fare as int64) as applied_fare
  from {{ source('sales_source', 'reservation_details') }}
)
select * from source