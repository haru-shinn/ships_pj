{{
  config(
    materialized='view'
  )
}}
with source as (
  select
    trim(reservation_id) as reservation_id
    , reservation_name
    , reservation_email
    , reservation_date
  from {{ source('sales_source', 'reservations') }}
)
select * from source