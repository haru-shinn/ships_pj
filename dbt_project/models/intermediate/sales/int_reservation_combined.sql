{{
  config(
    materialized='table',
  )
}}
with joined_tbl as (
  select
    -- 予約・予約明細情報
    res.reservation_id
    , res_d.detail_id
    , res_d.schedule_id
    , res.reservation_date
    , res.reservation_day_of_week

    -- スケジュール情報
    , ves_sch.ship_id
    , ves_sch.ship_name
    , sch.departure_date
    , sch.departure_day_of_week
    , sch.arrival_date
    , sch.arrival_day_of_week
    , ves_sch.dep_port_name
    , ves_sch.arr_port_name

    -- リードタイム情報
    , date_diff(sch.departure_date, res.reservation_date, DAY) as lead_time

    -- 顧客属性
    , res_d.passenger_id
    , if(res_d.passenger_id is not null, true, false) as is_member_flg
    , res.reservation_name
    , res_d.passenger_type

    -- 料金・クラス情報
    , res_d.room_class_id
    , rcm.room_class_name
    , res_d.applied_fare

    -- メタデータ
    , current_timestamp() as updated_at
  from
    {{ ref('stg_sales__reservations') }} as res
    inner join {{ ref('stg_sales__reservation_details') }} as res_d
      on res.reservation_id = res_d.reservation_id
    inner join {{ ref('stg_route_operations__schedules') }} as sch
      on res_d.schedule_id = sch.schedule_id
    inner join {{ ref('int_vessel_schedules') }} as ves_sch
      on res_d.schedule_id = ves_sch.schedule_id
    inner join {{ ref('stg_ship_management__room_class_masters') }} as rcm
      on res_d.room_class_id = rcm.room_class_id
)
select * from joined_tbl