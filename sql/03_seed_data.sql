-- Real business seed data for ED's Inventory & Storage System
-- Sources: ED Inventory Tracker.csv, All_Manifests_Apr17.xlsx, New_Manifests_Apr21.xlsx
-- All items sourced from Direct Supply (AUCTION)
-- Storage: Unit 3577 (TVs), Unit G76 (Audio/Receivers), Unit 3575 (Home Theater misc)

USE inventory_storage_db;

SET SESSION sql_mode = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

SET FOREIGN_KEY_CHECKS = 0;
DROP TRIGGER IF EXISTS prevent_negative_inventory;
TRUNCATE TABLE Inventory_Transaction;
TRUNCATE TABLE Purchase_or_Order;
TRUNCATE TABLE Product;
TRUNCATE TABLE Source_or_Supplier;
TRUNCATE TABLE Storage_Site;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- STORAGE SITES
-- ============================================================
INSERT INTO Storage_Site (site_id, site_name, city, state) VALUES
    (1, 'Unit 3577', 'Plano', 'TX'),
    (2, 'Unit G76',  'Plano', 'TX'),
    (3, 'Unit 3575', 'Plano', 'TX');

-- ============================================================
-- SOURCE / SUPPLIER
-- ============================================================
INSERT INTO Source_or_Supplier (source_id, source_name, source_type) VALUES
    (1, 'Direct Supply', 'AUCTION');

-- ============================================================
-- PRODUCTS
-- product_condition: all GOOD (Grade B) by default
--   exceptions: STRAZ3000ES (C) and STRAZ5000ES (Apr21 Grade C) = FAIR
--               SUWL855 (Returns grade) = POOR
-- profit = total realized profit from sales log
-- ============================================================

-- Site 1: Unit 3577 — TVs (product_id 1–21)
INSERT INTO Product (
    product_id, product_name, status, cost, profit,
    product_condition, date_added, date_sold, product_quantity, site_id
) VALUES
    (1,  'SONY KD32W830K',   'IN_STOCK',     211.20,   -45.20, 'GOOD', '2026-04-01', NULL,         4,  1),
    (2,  'SONY XR48A90K',    'IN_STOCK',     244.97,  1174.06, 'GOOD', '2026-04-01', NULL,         2,  1),
    (3,  'SONY XR55X90L',    'IN_STOCK',     260.15,     0.00, 'GOOD', '2026-04-01', NULL,         1,  1),
    (4,  'SONY K65X95K',     'IN_STOCK',     474.15,     0.00, 'GOOD', '2026-04-01', NULL,         1,  1),
    (5,  'SONY K65XR80',     'IN_STOCK',     682.15,     0.00, 'GOOD', '2026-04-01', NULL,         2,  1),
    (6,  'SONY KD65X77CL',   'IN_STOCK',     485.15,     0.00, 'GOOD', '2026-04-01', NULL,         1,  1),
    (7,  'SONY KD65X80CK',   'IN_STOCK',     280.15,     0.00, 'GOOD', '2026-04-01', NULL,         1,  1),
    (8,  'SONY K75XR90',     'SOLD',         605.15,   194.85, 'GOOD', '2026-04-01', '2026-04-21', 0,  1),
    (9,  'SONY KD85X80CK',   'IN_STOCK',     497.51,     0.00, 'GOOD', '2026-04-01', NULL,         3,  1),
    (10, 'SONY XR85X90CL',   'IN_STOCK',     665.15,     0.00, 'GOOD', '2026-04-01', NULL,         1,  1),
    (11, 'SONY XR65A80L',    'IN_STOCK',     551.15,     0.00, 'GOOD', '2026-04-01', NULL,         1,  1),
    (12, 'SONY K77XR8B',     'SOLD',         714.15,   585.85, 'GOOD', '2026-04-01', '2026-04-12', 0,  1),
    (13, 'SONY K55S20M2',    'IN_STOCK',     166.15,     0.00, 'GOOD', '2026-04-01', NULL,         1,  1),
    (14, 'SONY K55XR70',     'IN_STOCK',     331.97,     0.00, 'GOOD', '2026-04-01', NULL,         3,  1),
    (15, 'SONY K55XR80',     'IN_STOCK',     425.82,     0.00, 'GOOD', '2026-04-01', NULL,         1,  1),
    (16, 'SONY K55XR8B',     'IN_STOCK',     357.76,     0.00, 'GOOD', '2026-04-01', NULL,         1,  1),
    (17, 'SONY K65XR70',     'IN_STOCK',     326.82,     0.00, 'GOOD', '2026-04-01', NULL,         1,  1),
    (18, 'SONY K85S30',      'SOLD',         408.23,   391.77, 'GOOD', '2026-04-01', '2026-04-18', 0,  1),
    (19, 'SONY SDM27Q10SB',  'IN_STOCK',     436.35,   162.65, 'GOOD', '2026-04-01', NULL,         5,  1),
    (20, 'SONY SDM27U9M2B',  'IN_STOCK',     351.05,   869.80, 'GOOD', '2026-04-01', NULL,         2,  1),
    (21, 'SONY XR42A90K',    'IN_STOCK',     459.87,     0.00, 'GOOD', '2026-04-01', NULL,         1,  1);

-- Site 2: Unit G76 — Speakers, Receivers, Soundbars (product_id 22–43)
INSERT INTO Product (
    product_id, product_name, status, cost, profit,
    product_condition, date_added, date_sold, product_quantity, site_id
) VALUES
    (22, 'SONY SRSULT70',      'IN_STOCK',    169.92,   864.80, 'GOOD', '2026-04-01', NULL,         13, 2),
    (23, 'SONY SRSXP700',      'SOLD',        130.15,   119.85, 'GOOD', '2026-04-01', '2026-04-04', 0,  2),
    (24, 'SONY SRSXV500',      'SOLD',        128.94,    60.06, 'GOOD', '2026-04-01', '2026-04-04', 0,  2),
    (25, 'SONY SRSXG500',      'SOLD',        151.94,    38.06, 'GOOD', '2026-04-01', '2026-04-03', 0,  2),
    (26, 'SONY SRSULT50/W',    'SOLD',         98.35,   218.26, 'GOOD', '2026-04-01', '2026-04-15', 0,  2),
    (27, 'SONY SRSULT50/WB',   'SOLD',         83.15,    58.85, 'GOOD', '2026-04-01', '2026-04-14', 0,  2),
    (28, 'SONY SRSXV800',      'IN_STOCK',    289.10,     0.00, 'GOOD', '2026-04-01', NULL,         3,  2),
    (29, 'SONY STRAZ3000ES',   'IN_STOCK',    559.55,   973.35, 'GOOD', '2026-04-01', NULL,         8,  2),
    (30, 'SONY STRAZ3000ES C', 'IN_STOCK',    330.94,     0.00, 'FAIR', '2026-04-01', NULL,         1,  2),
    (31, 'SONY STRAZ1000ES',   'IN_STOCK',    340.39,   830.44, 'GOOD', '2026-04-01', NULL,         14, 2),
    (32, 'SONY STRAZ5000ES',   'IN_STOCK',    763.08,   815.92, 'FAIR', '2026-04-01', NULL,         2,  2),
    (33, 'SONY STRAN1000',     'SOLD',        202.23,  1545.85, 'GOOD', '2026-04-01', '2026-04-28', 0,  2),
    (34, 'SONY STRDH590',      'IN_STOCK',    131.53,   817.23, 'GOOD', '2026-04-01', NULL,         37, 2),
    (35, 'SONY STRDH790',      'IN_STOCK',    153.07,  1641.37, 'GOOD', '2026-04-01', NULL,         7,  2),
    (36, 'SONY STRDH190',      'IN_STOCK',    134.42,   -10.42, 'GOOD', '2026-04-01', NULL,         1,  2),
    (37, 'SONY HTSC40',        'IN_STOCK',     81.15,     0.00, 'GOOD', '2026-04-01', NULL,         2,  2),
    (38, 'SONY HTS40R',        'IN_STOCK',     73.65,    39.35, 'GOOD', '2026-04-01', NULL,         1,  2),
    (39, 'SONY HTS400',        'IN_STOCK',     95.15,     0.00, 'GOOD', '2026-04-01', NULL,         5,  2),
    (40, 'SONY HTS60',         'SOLD',        143.92,   560.16, 'GOOD', '2026-04-01', '2026-04-23', 0,  2),
    (41, 'SONY HTS100F',       'IN_STOCK',    106.18,  -106.36, 'GOOD', '2026-04-01', NULL,         1,  2),
    (42, 'SONY HTA7000',       'IN_STOCK',    154.52,   770.96, 'GOOD', '2026-04-01', NULL,         4,  2),
    (43, 'SONY SARS8',         'IN_STOCK',     99.69,     0.00, 'GOOD', '2026-04-01', NULL,         1,  2);

-- Site 3: Unit 3575 — Home Theater misc (product_id 44–50)
-- Only items with manifest records. Others excluded per project scope.
INSERT INTO Product (
    product_id, product_name, status, cost, profit,
    product_condition, date_added, date_sold, product_quantity, site_id
) VALUES
    (44, 'SONY HTA3000',   'IN_STOCK',  82.39,     0.00, 'GOOD', '2026-04-21', NULL,         1,  3),
    (45, 'SONY HTA5000',   'IN_STOCK', 131.46,     0.00, 'GOOD', '2026-04-21', NULL,         1,  3),
    (46, 'SONY HTB600',    'IN_STOCK', 179.33,   220.67, 'GOOD', '2026-04-21', NULL,         2,  3),
    (47, 'SONY PSLX310BT', 'IN_STOCK', 132.20,     0.00, 'GOOD', '2026-04-21', NULL,         1,  3),
    (48, 'SONY SACS9',     'SOLD',      82.39,   164.61, 'GOOD', '2026-04-21', '2026-04-24', 0,  3),
    (49, 'SONY SSCS8',     'IN_STOCK', 132.20,     0.00, 'GOOD', '2026-04-21', NULL,         1,  3),
    (50, 'SONY SUWL855',   'SOLD',      72.48,   324.52, 'POOR', '2026-04-21', '2026-04-27', 0,  3);

-- ============================================================
-- PURCHASES (one per product, unit_cost = avg cost from tracker)
-- ============================================================
INSERT INTO Purchase_or_Order (purchase_id, purchase_date, purchase_quantity, unit_cost, product_id, source_id) VALUES
    -- Site 1: TVs
    (1,  '2026-04-01', 5,  211.20, 1,  1),
    (2,  '2026-04-01', 4,  244.97, 2,  1),
    (3,  '2026-04-01', 1,  260.15, 3,  1),
    (4,  '2026-04-01', 1,  474.15, 4,  1),
    (5,  '2026-04-01', 2,  682.15, 5,  1),
    (6,  '2026-04-01', 1,  485.15, 6,  1),
    (7,  '2026-04-01', 1,  280.15, 7,  1),
    (8,  '2026-04-01', 1,  605.15, 8,  1),
    (9,  '2026-04-01', 3,  497.51, 9,  1),
    (10, '2026-04-01', 1,  665.15, 10, 1),
    (11, '2026-04-01', 1,  551.15, 11, 1),
    (12, '2026-04-01', 1,  714.15, 12, 1),
    (13, '2026-04-01', 1,  166.15, 13, 1),
    (14, '2026-04-01', 3,  331.97, 14, 1),
    (15, '2026-04-01', 1,  425.82, 15, 1),
    (16, '2026-04-01', 1,  357.76, 16, 1),
    (17, '2026-04-01', 1,  326.82, 17, 1),
    (18, '2026-04-01', 1,  408.23, 18, 1),
    (19, '2026-04-01', 6,  436.35, 19, 1),
    (20, '2026-04-01', 6,  351.05, 20, 1),
    (21, '2026-04-01', 1,  459.87, 21, 1),
    -- Site 2: Audio/Receivers/Soundbars
    (22, '2026-04-01', 23, 169.92, 22, 1),
    (23, '2026-04-01', 1,  130.15, 23, 1),
    (24, '2026-04-01', 1,  128.94, 24, 1),
    (25, '2026-04-01', 1,  151.94, 25, 1),
    (26, '2026-04-01', 5,   98.35, 26, 1),
    (27, '2026-04-01', 1,   83.15, 27, 1),
    (28, '2026-04-01', 3,  289.10, 28, 1),
    (29, '2026-04-01', 11, 559.55, 29, 1),
    (30, '2026-04-01', 1,  330.94, 30, 1),
    (31, '2026-04-01', 18, 340.39, 31, 1),
    (32, '2026-04-01', 3,  763.08, 32, 1),
    (33, '2026-04-01', 5,  202.23, 33, 1),
    (34, '2026-04-01', 46, 131.53, 34, 1),
    (35, '2026-04-01', 16, 153.07, 35, 1),
    (36, '2026-04-01', 2,  134.42, 36, 1),
    (37, '2026-04-01', 2,   81.15, 37, 1),
    (38, '2026-04-01', 2,   73.65, 38, 1),
    (39, '2026-04-01', 5,   95.15, 39, 1),
    (40, '2026-04-01', 2,  143.92, 40, 1),
    (41, '2026-04-01', 3,  106.18, 41, 1),
    (42, '2026-04-01', 6,  154.52, 42, 1),
    (43, '2026-04-01', 1,   99.69, 43, 1),
    -- Site 3: Home Theater misc (Apr 21 manifest)
    (44, '2026-04-21', 1,   80.45, 44, 1),
    (45, '2026-04-21', 1,  130.26, 45, 1),
    (46, '2026-04-21', 3,  177.39, 46, 1),
    (47, '2026-04-21', 1,  130.26, 47, 1),
    (48, '2026-04-21', 1,   80.45, 48, 1),
    (49, '2026-04-21', 1,  130.26, 49, 1),
    (50, '2026-04-21', 1,   70.54, 50, 1);

-- ============================================================
-- INVENTORY TRANSACTIONS
-- PURCHASE entries first, then SALE entries chronologically
-- unit_price for PURCHASE = avg cost; for SALE = actual sale price
-- ============================================================

INSERT INTO Inventory_Transaction (transaction_date, transaction_type, transaction_quantity, unit_price, product_id) VALUES
-- ── PURCHASE events ──────────────────────────────────────────
('2026-04-01', 'PURCHASE', 5,  211.20, 1),   -- KD32W830K
('2026-04-01', 'PURCHASE', 4,  244.97, 2),   -- XR48A90K
('2026-04-01', 'PURCHASE', 1,  260.15, 3),   -- XR55X90L
('2026-04-01', 'PURCHASE', 1,  474.15, 4),   -- K65X95K
('2026-04-01', 'PURCHASE', 2,  682.15, 5),   -- K65XR80
('2026-04-01', 'PURCHASE', 1,  485.15, 6),   -- KD65X77CL
('2026-04-01', 'PURCHASE', 1,  280.15, 7),   -- KD65X80CK
('2026-04-01', 'PURCHASE', 1,  605.15, 8),   -- K75XR90
('2026-04-01', 'PURCHASE', 3,  497.51, 9),   -- KD85X80CK
('2026-04-01', 'PURCHASE', 1,  665.15, 10),  -- XR85X90CL
('2026-04-01', 'PURCHASE', 1,  551.15, 11),  -- XR65A80L
('2026-04-01', 'PURCHASE', 1,  714.15, 12),  -- K77XR8B
('2026-04-01', 'PURCHASE', 1,  166.15, 13),  -- K55S20M2
('2026-04-01', 'PURCHASE', 3,  331.97, 14),  -- K55XR70
('2026-04-01', 'PURCHASE', 1,  425.82, 15),  -- K55XR80
('2026-04-01', 'PURCHASE', 1,  357.76, 16),  -- K55XR8B
('2026-04-01', 'PURCHASE', 1,  326.82, 17),  -- K65XR70
('2026-04-01', 'PURCHASE', 1,  408.23, 18),  -- K85S30
('2026-04-01', 'PURCHASE', 6,  436.35, 19),  -- SDM27Q10SB
('2026-04-01', 'PURCHASE', 6,  351.05, 20),  -- SDM27U9M2B
('2026-04-01', 'PURCHASE', 1,  459.87, 21),  -- XR42A90K
('2026-04-01', 'PURCHASE', 23, 169.92, 22),  -- SRSULT70
('2026-04-01', 'PURCHASE', 1,  130.15, 23),  -- SRSXP700
('2026-04-01', 'PURCHASE', 1,  128.94, 24),  -- SRSXV500
('2026-04-01', 'PURCHASE', 1,  151.94, 25),  -- SRSXG500
('2026-04-01', 'PURCHASE', 5,   98.35, 26),  -- SRSULT50/W
('2026-04-01', 'PURCHASE', 1,   83.15, 27),  -- SRSULT50/WB
('2026-04-01', 'PURCHASE', 3,  289.10, 28),  -- SRSXV800
('2026-04-01', 'PURCHASE', 11, 559.55, 29),  -- STRAZ3000ES
('2026-04-01', 'PURCHASE', 1,  330.94, 30),  -- STRAZ3000ES C
('2026-04-01', 'PURCHASE', 18, 340.39, 31),  -- STRAZ1000ES
('2026-04-01', 'PURCHASE', 3,  763.08, 32),  -- STRAZ5000ES
('2026-04-01', 'PURCHASE', 5,  202.23, 33),  -- STRAN1000
('2026-04-01', 'PURCHASE', 46, 131.53, 34),  -- STRDH590
('2026-04-01', 'PURCHASE', 16, 153.07, 35),  -- STRDH790
('2026-04-01', 'PURCHASE', 2,  134.42, 36),  -- STRDH190
('2026-04-01', 'PURCHASE', 2,   81.15, 37),  -- HTSC40
('2026-04-01', 'PURCHASE', 2,   73.65, 38),  -- HTS40R
('2026-04-01', 'PURCHASE', 5,   95.15, 39),  -- HTS400
('2026-04-01', 'PURCHASE', 2,  143.92, 40),  -- HTS60
('2026-04-01', 'PURCHASE', 3,  106.18, 41),  -- HTS100F
('2026-04-01', 'PURCHASE', 6,  154.52, 42),  -- HTA7000
('2026-04-01', 'PURCHASE', 1,   99.69, 43),  -- SARS8
('2026-04-21', 'PURCHASE', 1,   80.45, 44),  -- HTA3000
('2026-04-21', 'PURCHASE', 1,  130.26, 45),  -- HTA5000
('2026-04-21', 'PURCHASE', 3,  177.39, 46),  -- HTB600
('2026-04-21', 'PURCHASE', 1,  130.26, 47),  -- PSLX310BT
('2026-04-21', 'PURCHASE', 1,   80.45, 48),  -- SACS9
('2026-04-21', 'PURCHASE', 1,  130.26, 49),  -- SSCS8
('2026-04-21', 'PURCHASE', 1,   70.54, 50),  -- SUWL855

-- ── SALE events (chronological) ──────────────────────────────
('2026-04-01', 'SALE', 1,  518.00, 33),  -- STRAN1000
('2026-04-02', 'SALE', 1,  884.00, 29),  -- STRAZ3000ES
('2026-04-03', 'SALE', 1,  190.00, 25),  -- SRSXG500
('2026-04-03', 'SALE', 1,  124.00, 36),  -- STRDH190
('2026-04-03', 'SALE', 2,  495.00, 33),  -- STRAN1000 (2 units)
('2026-04-04', 'SALE', 1,  250.00, 23),  -- SRSXP700
('2026-04-04', 'SALE', 1,  189.00, 24),  -- SRSXV500
('2026-04-05', 'SALE', 2,  258.00, 22),  -- SRSULT70 (2 units)
('2026-04-05', 'SALE', 1,  540.00, 42),  -- HTA7000
('2026-04-05', 'SALE', 1,  564.00, 31),  -- STRAZ1000ES
('2026-04-05', 'SALE', 1, 1579.00, 32),  -- STRAZ5000ES
('2026-04-07', 'SALE', 3,  142.00, 26),  -- SRSULT50/W (3 units)
('2026-04-07', 'SALE', 1,  331.00, 35),  -- STRDH790
('2026-04-07', 'SALE', 1,  166.00, 1),   -- KD32W830K
('2026-04-08', 'SALE', 2,  250.00, 22),  -- SRSULT70 (2 units, Cash)
('2026-04-09', 'SALE', 1,  884.00, 29),  -- STRAZ3000ES
('2026-04-12', 'SALE', 1,  400.00, 40),  -- HTS60
('2026-04-12', 'SALE', 1,  540.00, 42),  -- HTA7000
('2026-04-12', 'SALE', 1, 1300.00, 12),  -- K77XR8B
('2026-04-13', 'SALE', 2,   53.00, 41),  -- HTS100F (2 units)
('2026-04-14', 'SALE', 1,  564.00, 31),  -- STRAZ1000ES
('2026-04-14', 'SALE', 1,  142.00, 27),  -- SRSULT50/WB
('2026-04-15', 'SALE', 1,  495.00, 33),  -- STRAN1000
('2026-04-15', 'SALE', 1,  142.00, 26),  -- SRSULT50/W
('2026-04-15', 'SALE', 1,  142.00, 26),  -- SRSULT50/W
('2026-04-15', 'SALE', 1,  832.00, 2),   -- XR48A90K
('2026-04-17', 'SALE', 1,  884.00, 29),  -- STRAZ3000ES
('2026-04-17', 'SALE', 1,  832.00, 2),   -- XR48A90K
('2026-04-18', 'SALE', 1,  113.00, 38),  -- HTS40R
('2026-04-18', 'SALE', 1,  193.00, 34),  -- STRDH590
('2026-04-18', 'SALE', 1,  800.00, 18),  -- K85S30
('2026-04-19', 'SALE', 2,  221.00, 34),  -- STRDH590 (2 units)
('2026-04-19', 'SALE', 1,  486.00, 20),  -- SDM27U9M2B
('2026-04-19', 'SALE', 1,  525.00, 31),  -- STRAZ1000ES
('2026-04-20', 'SALE', 1,  331.00, 35),  -- STRDH790
('2026-04-20', 'SALE', 1,  258.00, 22),  -- SRSULT70
('2026-04-20', 'SALE', 1,  539.00, 31),  -- STRAZ1000ES
('2026-04-21', 'SALE', 1,  574.00, 20),  -- SDM27U9M2B
('2026-04-21', 'SALE', 1,  258.00, 22),  -- SRSULT70
('2026-04-21', 'SALE', 1,  800.00, 8),   -- K75XR90
('2026-04-21', 'SALE', 1,  226.00, 34),  -- STRDH590
('2026-04-22', 'SALE', 1,  351.00, 35),  -- STRDH790
('2026-04-23', 'SALE', 1,  448.00, 40),  -- HTS60
('2026-04-23', 'SALE', 1,  351.00, 35),  -- STRDH790
('2026-04-24', 'SALE', 1,  331.00, 35),  -- STRDH790
('2026-04-24', 'SALE', 1,  228.00, 34),  -- STRDH590
('2026-04-24', 'SALE', 1,  228.00, 34),  -- STRDH590
('2026-04-24', 'SALE', 1,  247.00, 48),  -- SACS9
('2026-04-24', 'SALE', 1,  331.00, 35),  -- STRDH790
('2026-04-24', 'SALE', 1,  607.00, 20),  -- SDM27U9M2B
('2026-04-25', 'SALE', 1,  258.00, 22),  -- SRSULT70
('2026-04-25', 'SALE', 1,  228.00, 34),  -- STRDH590
('2026-04-26', 'SALE', 1,  258.00, 22),  -- SRSULT70
('2026-04-26', 'SALE', 1,  258.00, 22),  -- SRSULT70
('2026-04-26', 'SALE', 1,  228.00, 34),  -- STRDH590
('2026-04-26', 'SALE', 1,  607.00, 20),  -- SDM27U9M2B
('2026-04-27', 'SALE', 1,  258.00, 22),  -- SRSULT70
('2026-04-27', 'SALE', 1,  397.00, 50),  -- SUWL855
('2026-04-27', 'SALE', 1,  400.00, 46),  -- HTB600
('2026-04-28', 'SALE', 1,  228.00, 34),  -- STRDH590
('2026-04-28', 'SALE', 1,  331.00, 35),  -- STRDH790
('2026-04-28', 'SALE', 1,  599.00, 19),  -- SDM27Q10SB
('2026-04-28', 'SALE', 1,  554.00, 33);  -- STRAN1000

-- ============================================================
-- Recreate trigger after seed data is loaded
-- ============================================================
DELIMITER //
CREATE TRIGGER prevent_negative_inventory
BEFORE INSERT ON Inventory_Transaction
FOR EACH ROW
BEGIN
    DECLARE current_quantity INT UNSIGNED DEFAULT 0;
    SELECT COALESCE(SUM(product_quantity), 0)
    INTO current_quantity
    FROM Product
    WHERE product_id = NEW.product_id;
    IF NEW.transaction_type IN ('SALE', 'TRANSFER_OUT', 'ADJUSTMENT_OUT')
        AND current_quantity < NEW.transaction_quantity THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Not enough inventory for this transaction.';
    END IF;
END//
DELIMITER ;
