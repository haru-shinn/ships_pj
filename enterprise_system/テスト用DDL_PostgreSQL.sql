--------------------------------------------
-- 船の予約管理用のDDL
-- 本番環境用スキーマ：ships_raw

-- データベース：Cloud SQL for PostgreSQL
-- スキーマ：Terraform管理
-- テーブル：SQLファイル管理
--------------------------------------------

/* マスタ系テーブル（船・客室・港） */

/* 船マスタ（基本情報）テーブル */
DROP TABLE IF EXISTS ships_raw_dev.ships CASCADE;
CREATE TABLE IF NOT EXISTS ships_raw_dev.ships (
  ship_id CHAR(4) PRIMARY KEY
  , ship_name VARCHAR(64) NOT NULL
  , length DECIMAL(5, 2) NOT NULL
  , width DECIMAL(4, 2) NOT NULL
  , gross_tonnage INTEGER NOT NULL
  , service_speed INTEGER NOT NULL
  , max_passenger_capacity INTEGER NOT NULL
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
DROP TABLE IF EXISTS ships_raw.room_class_master CASCADE;
CREATE TABLE IF NOT EXISTS ships_raw.room_class_master (
  room_class_id CHAR(2)
  , room_class_name VARCHAR(16)
  , capacity_per_room INTEGER
  , notice VARCHAR(256)
  , PRIMARY KEY (room_class_id)
  , UNIQUE (room_class_id, capacity_per_room)
);

INSERT INTO ships_raw_dev.room_class_master VALUES
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
DROP TABLE IF EXISTS ships_raw_dev.ship_room_classes CASCADE;
CREATE TABLE IF NOT EXISTS ships_raw_dev.ship_room_classes (
  ship_id CHAR(4)
  , room_class_id CHAR(2)
  , room_count INTEGER
  , capacity_per_room INTEGER
  , total_occupancy INTEGER GENERATED ALWAYS AS (room_count * capacity_per_room) STORED
  , PRIMARY KEY (ship_id, room_class_id)
  , FOREIGN KEY (room_class_id, capacity_per_room) REFERENCES ships_raw_dev.room_class_master(room_class_id, capacity_per_room)
);

INSERT INTO ships_raw_dev.ship_room_classes (ship_id, room_class_id, room_count, capacity_per_room, total_occupancy) VALUES
 -- Apple, Banana (502名)
 ('S001', 'SY', 20, 2, 40), ('S001', 'SW', 5, 4, 20), ('S001', 'DX', 40, 1, 40), ('S001', 'TR', 50, 1, 50), ('S001', 'EC', 22, 16, 352)
 ,('S002', 'SY', 20, 2, 40), ('S002', 'SW', 5, 4, 20), ('S002', 'DX', 40, 1, 40), ('S002', 'TR', 50, 1, 50), ('S002', 'EC', 22, 16, 352)
 -- Orange, Grape (540名 ※定員合計に基づき入力)
 ,('S003', 'FC', 6, 2, 12), ('S003', 'SC', 6, 8, 48), ('S003', 'TC', 12, 40, 480)
 ,('S004', 'FC', 6, 2, 12), ('S004', 'SC', 6, 8, 48), ('S004', 'TC', 12, 40, 480)
;


/* 港テーブル */
DROP TABLE IF EXISTS ships_raw_dev.ports CASCADE;
CREATE TABLE IF NOT EXISTS ships_raw_dev.ports (
  port_id CHAR(2) PRIMARY KEY
  , port_name VARCHAR(64)
);

INSERT INTO ships_raw_dev.ports VALUES
 ('P1', 'ABC港'), ('P2', 'XYZ港'), ('P3', 'PQL港')
;


/* 航路・区間・ダイヤ構成 */

/* 航路テーブル */
DROP TABLE IF EXISTS ships_raw_dev.rooutes;
CREATE TABLE IF NOT EXISTS ships_raw_dev.rooutes (
  route_id CHAR(3) PRIMARY KEY
  , departure_port_id CHAR(2) REFERENCES ships_raw_dev.ports(port_id)
  , arrival_port_id CHAR(2) REFERENCES ships_raw_dev.ports(port_id)
);

INSERT INTO ships_raw_dev.rooutes (route_id, departure_port_id, arrival_port_id) VALUES
 ('R1', 'P1', 'P2'), ('R2', 'P1', 'P3')
;


/* 区間テーブル */
DROP TABLE IF EXISTS ships_raw_dev.sections;
CREATE TABLE IF NOT EXISTS ships_raw_dev.sections (
  section_id CHAR(2) PRIMARY KEY
  , departure_port_id CHAR(2) REFERENCES ships_raw_dev.ports(port_id)
  , arrival_port_id CHAR(2) REFERENCES ships_raw_dev.ports(port_id)
  , standard_time_required CHAR(8)
  , notice CHAR(256)
);

INSERT INTO ships_raw_dev.sections (section_id, departure_port_id, arrival_port_id, travel_time_minutes) VALUES
 ('S1', 'P1', 'P2', 195) -- ABC->XYZ (3h15m)
 ,('S2', 'P2', 'P1', 195) -- XYZ->ABC
 ,('S3', 'P1', 'P3', 100) -- ABC->PQL (1h40m)
 ,('S4', 'P3', 'P1', 100) -- PQL->ABC
;


/* 航路区間構成テーブル */
DROP TABLE IF EXISTS ships_raw_dev.route_sections;
CREATE TABLE IF NOT EXISTS ships_raw_dev.route_sections (
  section_id CHAR(2) REFERENCES ships_raw_dev.sections(section_id)
  , route_id CHAR(3) REFERENCES ships_raw_dev.rooutes(route_id)
  , PRIMARY KEY (section_id, route_id)
);

INSERT INTO ships_raw_dev.route_sections (section_id, route_id) VALUES
('S1', 'R1'), ('S2', 'R1'), ('S3', 'R2'), ('S4', 'R2')
;


/* 運行スケジュール */

/* 運行スケジュールテーブル */
DROP TABLE IF EXISTS ships_raw_dev.schedule;
CREATE TABLE IF NOT EXISTS ships_raw_dev.schedule (
  schedule_id CHAR(14)
  , route_id CHAR(3) REFERENCES ships_raw_dev.rooutes(route_id)
  , section_id CHAR(2) REFERENCES ships_raw_dev.sections(section_id)
  , departure_time TIMESTAMP
  , arrival_time TIMESTAMP
  , ship_id CHAR(4) REFERENCES ships_raw_dev.ships(ship_id)
);

DELETE FROM ships_raw_dev.schedule;
INSERT INTO ships_raw_dev.schedule (
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


/* 予約・在庫 */

/* 予約基本情報テーブル */
DROP TABLE IF EXISTS ships_raw_dev.reservations;
CREATE TABLE IF NOT EXISTS ships_raw_dev.reservations (
  reservation_id CHAR(12)
  , rep_name CHAR(256)
  , rep_email CHAR(256)
  , reservation_date DATE
);


/* 予約明細情報テーブル */
DROP TABLE IF EXISTS ships_raw_dev.reservation_details;
CREATE TABLE IF NOT EXISTS ships_raw_dev.reservation_details (
  reservation_id CHAR(12) REFERENCES ships_raw_dev.reservations(reservation_id)
  , detail_id CHAR(3)
  , section_id CHAR(2) REFERENCES ships_raw_dev.sections(section_id)
  , schedule_id CHAR(14) REFERENCES ships_raw_dev.schedule(schedule_id)
  , passenger_id CHAR(8)
  , passenger_type CHAR(8)
  , ship_id CHAR(4) REFERENCES ships_raw_dev.ships(ship_id)
  , room_class_id CHAR(2)
  , applied_fare INTEGER
  , (reservation_id, detail_id, section_id)
  , FOREIGN KEY (room_class_id) REFERENCES ships_raw_dev.room_class_master(room_class_id)
);


/* 在庫テーブル */
DROP TABLE IF EXISTS ships_raw.inventry;
CREATE TABLE IF NOT EXISTS ships_raw.inventry (
  schedule_id CHAR(14)
  , section_id CHAR(2)
  , room_class_id CHAR(2)
  , room_count INTEGER
  , remaining_room_cnt INTEGER
  , num_of_people INTEGER
  , remaining_num_of_people INTEGER
  , (schedule_id, section_id, room_class_id)
  , FOREIGN KEY (room_class_id) REFERENCES ships_raw_dev.room_class_master(room_class_id)
  , FOREIGN KEY (section_id) REFERENCES ships_raw_dev.sections(section_id)
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

