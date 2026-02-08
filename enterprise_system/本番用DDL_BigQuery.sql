--------------------------------------------
-- 船の予約管理用のDDL
-- 本番環境用スキーマ：ships_raw

-- データベース：BigQuery
-- スキーマ：Terraform管理
-- テーブル：SQLファイル管理
--------------------------------------------

/* マスタ系テーブル（船・客室・港） */

/* 船マスタ（基本情報）テーブル */
DROP TABLE IF EXISTS ships_raw_dev.ships;
CREATE TABLE IF NOT EXISTS ships_raw_dev.ships (
  ship_id STRING
  , ship_name STRING NOT NULL
  , length DECIMAL(5, 2) NOT NULL
  , width DECIMAL(4, 2) NOT NULL
  , gross_tonnage INT64 NOT NULL
  , service_speed INT64 NOT NULL
  , max_passenger_capacity INT64 NOT NULL
  , start_date DATE NOT NULL
  , end_date DATE
);


/* 客室クラス定義マスタテーブル */
DROP TABLE IF EXISTS ships_raw_dev.room_class_master;
CREATE TABLE IF NOT EXISTS ships_raw_dev.room_class_master (
  room_class_id STRING
  , room_class_name STRING
  , capacity_per_room INT64
  , notice STRING
);


/* 船別客室設定テーブル */
DROP TABLE IF EXISTS ships_raw_dev.ship_room_classes;
CREATE TABLE ships_raw_dev.ship_room_classes (
  ship_id STRING
  , room_class_id STRING
  , room_count INT64
  , capacity_per_room INT64
  , total_occupancy INT64
);


/* 港テーブル */
DROP TABLE IF EXISTS ships_raw_dev.ports;
CREATE TABLE ships_raw_dev.ports (
  port_id STRING
  , port_name STRING
);


/* 航路・区間・ダイヤ構成 */

/* 航路テーブル */
DROP TABLE IF EXISTS ships_raw_dev.rooutes;
CREATE TABLE IF NOT EXISTS ships_raw_dev.rooutes (
  route_id STRING
  , departure_port_id STRING
  , arrival_port_id STRING
);


/* 区間テーブル */
DROP TABLE IF EXISTS ships_raw_dev.sections;
CREATE TABLE IF NOT EXISTS ships_raw_dev.sections (
  section_id STRING
  , departure_port_id STRING
  , arrival_port_id STRING
  , travel_time_minutes INT64
)
;


/* 航路区間構成テーブル */
DROP TABLE IF EXISTS ships_raw_dev.route_sections;
CREATE TABLE IF NOT EXISTS ships_raw_dev.route_sections (
  section_id STRING
  , route_id STRING
);


/* 運行スケジュール（24時間運用・自動生成） */

/* 運行スケジュールテーブル */
DROP TABLE IF EXISTS ships_raw_dev.schedule;
CREATE TABLE IF NOT EXISTS ships_raw_dev.schedule (
  schedule_id STRING
  , route_id STRING
  , section_id STRING 
  , departure_date DATE
  , arrival_date DATE
  , departure_time DATETIME
  , arrival_time DATETIME
  , ship_id STRING
);


/* 予約・在庫 */

/* 予約基本情報テーブル */
DROP TABLE IF EXISTS ships_raw_dev.reservations;
CREATE TABLE IF NOT EXISTS ships_raw_dev.reservations (
  reservation_id STRING
  , rep_name STRING
  , rep_email STRING
  , reservation_date DATE
);


/* 予約明細情報テーブル */
DROP TABLE IF EXISTS ships_raw_dev.reservation_details;
CREATE TABLE IF NOT EXISTS ships_raw_dev.reservation_details (
  reservation_id STRING
  , detail_id STRING
  , section_id STRING
  , schedule_id STRING
  , passenger_id STRING
  , passenger_type STRING
  , ship_id STRING
  , room_class_id STRING
  , applied_fare INT64
);


/* 在庫テーブル */
DROP TABLE IF EXISTS ships_raw.inventry;
CREATE TABLE IF NOT EXISTS ships_raw.inventry (
  schedule_id STRING
  , section_id STRING
  , room_class_id STRING
  , room_count INT64
  , remaining_room_cnt INT64
  , num_of_people INT64
  , remaining_num_of_people INT64
);
INSERT INTO ships_raw.inventry (
  schedule_id, section_id, room_class_id, room_count, remaining_room_cnt, num_of_people, remaining_num_of_people
)
SELECT 
  s.schedule_id
  , s.section_id
  , src.room_class_id 
  , src.room_count
  , src.room_count
  , src.total_occupancy
  , src.total_occupancy
FROM
  ships_raw_dev.schedule s
  INNER JOIN ships_raw_dev.ship_room_classes src ON s.ship_id = src.ship_id
;
