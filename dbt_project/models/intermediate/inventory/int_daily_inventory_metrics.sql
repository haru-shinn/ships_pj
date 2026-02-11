{{
  config(
    materialized='table'
  )
}}
with calculate_metrics as (
  select
      *
      -- 売れた部屋数 = 総部屋数 - 残り部屋数
      , (room_count - remaining_room_cnt) as sold_room_cnt
      
      -- 売れた人数 = 総定員 - 残り定員
      , (num_of_people - remaining_num_of_people) as sold_num_of_people
      
      -- 在庫消化率（部屋単位）: 売れた部屋数 / 総部屋数
      , safe_divide((room_count - remaining_room_cnt), room_count) as room_utilization_rate
      
      -- 在庫消化率（人数単位）: 売れた人数 / 総定員
      , safe_divide((num_of_people - remaining_num_of_people), num_of_people) as people_utilization_rate

      -- 完売フラグ
      , case when remaining_room_cnt = 0 then true else false end as is_sold_out

  from {{ ref('stg_sales__inventories') }}
)

select
    -- 主キー
    schedule_id
    , room_class_id
    
    -- 在庫指標
    , room_count
    , remaining_room_cnt
    , sold_room_cnt
    , num_of_people
    , remaining_num_of_people
    , sold_num_of_people
    
    -- 在庫消化率
    , round(room_utilization_rate, 4) as room_utilization_rate
    , round(people_utilization_rate, 4) as people_utilization_rate
    , is_sold_out
    
    -- メタデータ
    , current_timestamp() as updated_at
from 
  calculate_metrics