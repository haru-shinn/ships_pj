{{
  config(
    materialized='table'
  )
}}
with source as (
  select
    ship_id
    , ship_name
    , length
    , width
    , gross_tonnage
    , service_speed
    , max_passenger_capacity
    , start_date
    , end_date
  from {{ source('ships_source', 'ships') }}
)
select * from source