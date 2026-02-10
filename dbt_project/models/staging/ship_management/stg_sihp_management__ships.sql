{{
  config(
    materialized='view'
  )
}}
with source as (
  select
    trim(ship_id) as ship_id
    , ship_name
    , length
    , width
    , gross_tonnage
    , service_speed
    , max_passenger_capacity
    , start_date
    , end_date
  from {{ source('ship_management_source', 'ships') }}
)
select * from source