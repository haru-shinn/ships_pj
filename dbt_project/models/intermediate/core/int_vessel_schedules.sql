{{
  config(
    materialized = 'table',
    unique_key = 'schedule_id'
  )
}}
with join_tbl as (
  select
    -- スケジュール情報
    sch.schedule_id
    , ship.ship_id
    , ship.ship_name

    -- 出発・到着情報
    , departure_date
    , sch.departure_time
    , departure_day_of_week
    , arrival_date
    , sch.arrival_time
    , arrival_day_of_week

    -- 区間情報
    , sec.dep_section_seq
    , sec.arr_section_seq

    -- 港情報
    , dep_port.port_name as dep_port_name
    , arr_port.port_name as arr_port_name

    -- その他情報
    , sec.travel_time_minutes

    -- メタデータ
    , current_timestamp() as updated_at
  from
    {{ ref('stg_route_operations__schedules') }} as sch
    inner join {{ ref('stg_route_operations__sections') }} as sec
      on sch.route_id = sec.route_id
      and sch.departure_port_id = sec.departure_port_id
      and sch.arrival_port_id = sec.arrival_port_id
    inner join {{ ref('stg_route_operations__ports') }} as dep_port
      on sch.departure_port_id = dep_port.port_id
    inner join {{ ref('stg_route_operations__ports') }} as arr_port    
      on sch.arrival_port_id = arr_port.port_id
    inner join {{ ref('stg_ship_management__ships') }} as ship
      on sch.ship_id = ship.ship_id
)
select * from join_tbl