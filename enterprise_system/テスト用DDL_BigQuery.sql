--------------------------------------------
-- 船の予約管理用のDDL
-- 開発環境用スキーマ：ships_raw_dev

-- データベース：BigQuery
-- スキーマ：Terraform管理
-- テーブル：SQLファイル管理
--------------------------------------------

/* マスタ系テーブル（船・客室関連） */

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

INSERT INTO ships_raw_dev.ships (ship_id, ship_name, length, width, gross_tonnage, service_speed, max_passenger_capacity, start_date, end_date) VALUES
 ('S001', 'AppleMaru', 199.6, 27.1, 14500, 23, 502, '2022-05-01', '9999-12-31')
 , ('S002', 'BananaMaru', 199.6, 27.1, 14500, 23, 502, '2022-06-14', '9999-12-31')
 , ('S003', 'OrangeMaru', 95.1, 22.1, 15301, 20, 665, '2023-01-10', '9999-12-31')
 , ('S004', 'GrapeMaru', 95.1, 22.1, 15301, 20, 665, '2023-03-05', '9999-12-31')
;


/* 客室クラス定義マスタテーブル */
DROP TABLE IF EXISTS ships_raw_dev.room_class_masters;
CREATE TABLE IF NOT EXISTS ships_raw_dev.room_class_masters (
  room_class_id STRING
  , room_class_name STRING
  , capacity_per_room INT64
  , description STRING
);

INSERT INTO ships_raw_dev.room_class_masters VALUES
 ('SY', 'スイート（洋室）', 2, '二名個室。「室単位」で予約。')
 , ('SW', 'スイート（和室）', 4, '四名個室。「室単位」で予約。')
 , ('DX', 'デラックスシングル', 1, '一人用個室。「室単位」で予約。')
 , ('TR', 'ツーリング（寝台）', 1, '一人用個室。「室単位」で予約。')
 , ('EC', 'エコノミー（雑魚寝）', 16, '大部屋。「エリアの定員」で管理。部屋番号が固定されない。')
 , ('FC', '一等室', 2, '二名個室。「室単位」で予約。')
 , ('SC', '二等室', 8, '八名部屋。「エリアの定員」で管理。部屋番号が固定されない。')
 , ('TC', '三等室', 40, '大部屋。「エリアの定員」で管理。部屋番号が固定されない。。')
;


/* 船別客室設定テーブル */
DROP TABLE IF EXISTS ships_raw_dev.ship_room_classes;
CREATE TABLE ships_raw_dev.ship_room_classes (
  ship_id STRING
  , room_class_id STRING
  , room_count INT64
  , capacity_per_room INT64
  , total_occupancy INT64
);

INSERT INTO ships_raw_dev.ship_room_classes (ship_id, room_class_id, room_count, capacity_per_room, total_occupancy) VALUES
 -- Apple, Banana (502名)
 ('S001', 'SY', 20, 2, 40), ('S001', 'SW', 5, 4, 20), ('S001', 'DX', 40, 1, 40), ('S001', 'TR', 50, 1, 50), ('S001', 'EC', 22, 16, 352)
 ,('S002', 'SY', 20, 2, 40), ('S002', 'SW', 5, 4, 20), ('S002', 'DX', 40, 1, 40), ('S002', 'TR', 50, 1, 50), ('S002', 'EC', 22, 16, 352)
 -- Orange, Grape (540名 ※定員合計に基づき入力)
 ,('S003', 'FC', 6, 2, 12), ('S003', 'SC', 6, 8, 48), ('S003', 'TC', 12, 40, 480)
 ,('S004', 'FC', 6, 2, 12), ('S004', 'SC', 6, 8, 48), ('S004', 'TC', 12, 40, 480)
;



/* マスタ系テーブル（航路・港関連） */

/* 港テーブル */
DROP TABLE IF EXISTS ships_raw_dev.ports;
CREATE TABLE ships_raw_dev.ports (
  port_id STRING
  , port_name STRING
);

INSERT INTO ships_raw_dev.ports VALUES
 ('P1', 'ABC港'), ('P2', 'XYZ港'), ('P3', 'PQL港')
;


/* 航路テーブル */
DROP TABLE IF EXISTS ships_raw_dev.routes;
CREATE TABLE IF NOT EXISTS ships_raw_dev.routes (
  route_id STRING
  , departure_port_id STRING
  , arrival_port_id STRING
);

INSERT INTO ships_raw_dev.routes (route_id, departure_port_id, arrival_port_id) VALUES
 ('R1', 'P1', 'P2'), ('R2', 'P1', 'P3')
;


/* 区間テーブル */
DROP TABLE IF EXISTS ships_raw_dev.sections;
CREATE TABLE IF NOT EXISTS ships_raw_dev.sections (
  section_id STRING
  , departure_port_id STRING
  , arrival_port_id STRING
  , travel_time_minutes INT64
)
;

INSERT INTO ships_raw_dev.sections (section_id, departure_port_id, arrival_port_id, travel_time_minutes) VALUES
 ('S1', 'P1', 'P2', 195) -- ABC->XYZ (3h15m)
 ,('S2', 'P2', 'P1', 195) -- XYZ->ABC
 ,('S3', 'P1', 'P3', 100) -- ABC->PQL (1h40m)
 ,('S4', 'P3', 'P1', 100) -- PQL->ABC
;


/* 航路区間構成テーブル */
DROP TABLE IF EXISTS ships_raw_dev.route_sections;
CREATE TABLE IF NOT EXISTS ships_raw_dev.route_sections (
  section_id STRING
  , route_id STRING
);

INSERT INTO ships_raw_dev.route_sections (section_id, route_id) VALUES
('S1', 'R1'), ('S2', 'R1'), ('S3', 'R2'), ('S4', 'R2')
;


/* 運航ダイヤテーブル */
DROP TABLE IF EXISTS ships_raw_dev.schedules;
CREATE TABLE IF NOT EXISTS ships_raw_dev.schedules (
  schedule_id STRING
  , route_id STRING
  , section_id STRING
  , departure_time DATETIME
  , arrival_time DATETIME
  , ship_id STRING
);

DELETE FROM ships_raw_dev.schedules WHERE TRUE;
INSERT INTO ships_raw_dev.schedules (
    schedule_id, ship_id, route_id, section_id, departure_time, arrival_time
)
WITH date_range AS (
  SELECT day FROM UNNEST(GENERATE_DATE_ARRAY('2026-02-01', '2026-02-28')) day
)
, base_timetable AS (
  -- R1航路 (AppleMaru)
  SELECT 'S001' AS s_id, 'R1' AS r_id, 'S1' AS sec, '080000' AS d_t, '111500' AS a_t UNION ALL
  SELECT 'S001' AS s_id, 'R1' AS r_id, 'S2' AS sec, '131500' AS d_t, '163000' AS a_t UNION ALL
  SELECT 'S001' AS s_id, 'R1' AS r_id, 'S1' AS sec, '183000' AS d_t, '214500' AS a_t UNION ALL
  SELECT 'S001' AS s_id, 'R1' AS r_id, 'S2' AS sec, '234500' AS d_t, '030000' AS a_t UNION ALL

  -- R1航路 (BananaMaru)
  SELECT 'S002' AS s_id, 'R1' AS r_id, 'S2' AS sec, '080000' AS d_t, '111500' AS a_t UNION ALL
  SELECT 'S002' AS s_id, 'R1' AS r_id, 'S1' AS sec, '131500' AS d_t, '163000' AS a_t UNION ALL
  SELECT 'S002' AS s_id, 'R1' AS r_id, 'S2' AS sec, '183000' AS d_t, '214500' AS a_t UNION ALL
  SELECT 'S002' AS s_id, 'R1' AS r_id, 'S1' AS sec, '234500' AS d_t, '030000' AS a_t UNION ALL

  -- R2航路 (OrangeMaru)
  SELECT 'S003' AS s_id, 'R2' AS r_id, 'S3' AS sec, '070000' AS d_t, '084000' AS a_t UNION ALL
  SELECT 'S003' AS s_id, 'R2' AS r_id, 'S4' AS sec, '092000' AS d_t, '110000' AS a_t UNION ALL
  SELECT 'S003' AS s_id, 'R2' AS r_id, 'S3' AS sec, '114000' AS d_t, '132000' AS a_t UNION ALL
  SELECT 'S003' AS s_id, 'R2' AS r_id, 'S4' AS sec, '140000' AS d_t, '154000' AS a_t UNION ALL
  SELECT 'S003' AS s_id, 'R2' AS r_id, 'S3' AS sec, '162000' AS d_t, '180000' AS a_t UNION ALL
  SELECT 'S003' AS s_id, 'R2' AS r_id, 'S4' AS sec, '184000' AS d_t, '202000' AS a_t UNION ALL
  SELECT 'S003' AS s_id, 'R2' AS r_id, 'S3' AS sec, '210000' AS d_t, '224000' AS a_t UNION ALL
  SELECT 'S003' AS s_id, 'R2' AS r_id, 'S4' AS sec, '232000' AS d_t, '010000' AS a_t UNION ALL

  -- R2航路 (GrapeMaru)
  SELECT 'S004' AS s_id, 'R2' AS r_id, 'S4' AS sec, '070000' AS d_t, '084000' AS a_t UNION ALL
  SELECT 'S004' AS s_id, 'R2' AS r_id, 'S3' AS sec, '092000' AS d_t, '110000' AS a_t UNION ALL
  SELECT 'S004' AS s_id, 'R2' AS r_id, 'S4' AS sec, '114000' AS d_t, '132000' AS a_t UNION ALL
  SELECT 'S004' AS s_id, 'R2' AS r_id, 'S3' AS sec, '140000' AS d_t, '154000' AS a_t UNION ALL
  SELECT 'S004' AS s_id, 'R2' AS r_id, 'S4' AS sec, '162000' AS d_t, '180000' AS a_t UNION ALL
  SELECT 'S004' AS s_id, 'R2' AS r_id, 'S3' AS sec, '184000' AS d_t, '202000' AS a_t UNION ALL
  SELECT 'S004' AS s_id, 'R2' AS r_id, 'S4' AS sec, '210000' AS d_t, '224000' AS a_t UNION ALL
  SELECT 'S004' AS s_id, 'R2' AS r_id, 'S3' AS sec, '232000' AS d_t, '010000' AS a_t
)
SELECT 
  FORMAT_DATE('%Y%m%d', day) || s_id || sec || SUBSTR(d_t, 1, 2) AS schedule_id
  , s_id AS ship_id
  , r_id AS route_id
  , sec AS section_id
  , PARSE_DATETIME("%Y%m%d%H%M%S", FORMAT_DATE('%Y%m%d', day) || d_t) AS departure_time
  , IF(a_t < d_t
      , PARSE_DATETIME("%Y%m%d%H%M%S", FORMAT_DATE('%Y%m%d', DATE_ADD(day, INTERVAL 1 DAY)) || a_t)
      , PARSE_DATETIME("%Y%m%d%H%M%S", FORMAT_DATE('%Y%m%d', day) || a_t)
    ) AS arrival_time
FROM date_range CROSS JOIN base_timetable
;



/* トランザクション系テーブル（予約・在庫） */

/* 予約基本情報テーブル */
DROP TABLE IF EXISTS ships_raw_dev.reservations;
CREATE TABLE IF NOT EXISTS ships_raw_dev.reservations (
  reservation_id STRING
  , reservation_name STRING
  , reservation_email STRING
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
DROP TABLE IF EXISTS ships_raw_dev.inventories;
CREATE TABLE IF NOT EXISTS ships_raw_dev.inventories (
  schedule_id STRING
  , section_id STRING
  , room_class_id STRING
  , room_count INT64
  , remaining_room_cnt INT64
  , num_of_people INT64
  , remaining_num_of_people INT64
);
INSERT INTO ships_raw_dev.inventories (
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
  ships_raw_dev.schedules s
  INNER JOIN ships_raw_dev.ship_room_classes src ON s.ship_id = src.ship_id
;
