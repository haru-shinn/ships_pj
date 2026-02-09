{{
  config(
    materialized='table'
  )
}}
with source as (
  select
    reservation_id
    , rep_name
    , rep_email
    , reservation_date
  from {{ source('ships_source', 'reservations') }}
)
select * from source