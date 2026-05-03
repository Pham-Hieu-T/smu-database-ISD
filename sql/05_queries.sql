-- ============================================================
-- 05_queries.sql
-- Inventory & Storage Database — Query & Report File
-- ============================================================

USE inventory_storage_db;

-- ============================================================
-- QUERY 1: Inventory by Storage Site
-- What products are at each location and what is the total value?
-- ============================================================
SELECT
    ss.site_name                                    AS storage_unit,
    ss.city,
    p.product_name,
    p.status,
    p.product_condition,
    p.product_quantity                              AS qty_in_stock,
    p.cost                                          AS unit_cost,
    ROUND(p.product_quantity * p.cost, 2)           AS total_value
FROM Storage_Site ss
JOIN Product p ON p.site_id = ss.site_id
WHERE p.status IN ('IN_STOCK', 'RESERVED')
ORDER BY ss.site_name, p.product_name;

-- ============================================================
-- QUERY 2: Site-Level Inventory Summary
-- How much total inventory (units + dollars) is at each site?
-- ============================================================
SELECT
    ss.site_name                                    AS storage_unit,
    COUNT(p.product_id)                             AS product_types,
    SUM(p.product_quantity)                         AS total_units,
    ROUND(SUM(p.product_quantity * p.cost), 2)      AS total_inventory_value
FROM Storage_Site ss
LEFT JOIN Product p ON p.site_id = ss.site_id
    AND p.status IN ('IN_STOCK', 'RESERVED')
GROUP BY ss.site_id, ss.site_name
ORDER BY total_inventory_value DESC;

-- ============================================================
-- QUERY 3: Product Status Report
-- How many products are in each status category?
-- ============================================================
SELECT
    status,
    COUNT(*)                                        AS product_count,
    SUM(product_quantity)                           AS units_remaining
FROM Product
GROUP BY status
ORDER BY product_count DESC;

-- ============================================================
-- QUERY 4: Inventory Aging Report
-- How long has each product been sitting in stock?
-- Products over 30 days are flagged as aging.
-- ============================================================
SELECT
    p.product_name,
    ss.site_name                                    AS storage_unit,
    p.product_quantity                              AS qty_in_stock,
    p.date_added,
    DATEDIFF(CURDATE(), p.date_added)               AS days_in_stock,
    CASE
        WHEN DATEDIFF(CURDATE(), p.date_added) > 30 THEN 'AGING'
        ELSE 'OK'
    END                                             AS stock_health,
    ROUND(p.product_quantity * p.cost, 2)           AS capital_tied_up
FROM Product p
JOIN Storage_Site ss ON ss.site_id = p.site_id
WHERE p.status IN ('IN_STOCK', 'RESERVED')
ORDER BY days_in_stock DESC;

-- ============================================================
-- QUERY 5: Supplier Purchase History
-- What has been purchased from Direct Supply and at what cost?
-- ============================================================
SELECT
    s.source_name,
    s.source_type,
    COUNT(po.purchase_id)                           AS total_purchases,
    SUM(po.purchase_quantity)                       AS total_units_bought,
    ROUND(SUM(po.total_cost), 2)                    AS total_spent
FROM Source_or_Supplier s
LEFT JOIN Purchase_or_Order po ON po.source_id = s.source_id
GROUP BY s.source_id, s.source_name, s.source_type
ORDER BY total_spent DESC;

-- ============================================================
-- QUERY 6: Full Transaction History per Product
-- Every purchase and sale event for each product, in order.
-- ============================================================
SELECT
    p.product_name,
    it.transaction_date,
    it.transaction_type,
    it.transaction_quantity                         AS qty,
    it.unit_price,
    it.total_amount
FROM Product p
JOIN Inventory_Transaction it ON it.product_id = p.product_id
ORDER BY p.product_name, it.transaction_date, it.transaction_id;

-- ============================================================
-- QUERY 7: Sales History — Every Sale with Profit per Unit
-- What sold, when, for how much, and what was the margin?
-- ============================================================
SELECT
    p.product_name,
    it.transaction_date                             AS sale_date,
    it.transaction_quantity                         AS qty_sold,
    it.unit_price                                   AS sale_price,
    p.cost                                          AS unit_cost,
    ROUND(it.unit_price - p.cost, 2)                AS profit_per_unit,
    it.total_amount                                 AS total_revenue,
    ROUND((it.unit_price - p.cost) * it.transaction_quantity, 2) AS total_profit
FROM Inventory_Transaction it
JOIN Product p ON p.product_id = it.product_id
WHERE it.transaction_type = 'SALE'
ORDER BY it.transaction_date, p.product_name;

-- ============================================================
-- QUERY 8: Cost & Profit Summary per Product
-- Capital invested vs realized profit for every product.
-- ============================================================
SELECT
    p.product_name,
    p.status,
    p.cost                                          AS unit_cost,
    p.product_quantity                              AS qty_remaining,
    ROUND(p.product_quantity * p.cost, 2)           AS remaining_capital,
    p.profit                                        AS realized_profit,
    CASE
        WHEN p.cost > 0 AND p.profit <> 0
            THEN CONCAT(ROUND((p.profit / p.cost) * 100, 1), '%')
        ELSE 'N/A'
    END                                             AS profit_margin
FROM Product p
ORDER BY realized_profit DESC;

-- ============================================================
-- QUERY 9: Overall Business Financial Summary (April 2026)
-- Live inventory value, realized profit, and April revenue.
-- Period: April 1–28, 2026 (full sales log collected to date)
-- ============================================================
SELECT
    ROUND(SUM(p.product_quantity * p.cost), 2)          AS live_inventory_value,
    ROUND(SUM(p.profit), 2)                             AS total_realized_profit,
    (SELECT ROUND(SUM(it.total_amount), 2)
     FROM Inventory_Transaction it
     WHERE it.transaction_type = 'SALE'
       AND it.transaction_date BETWEEN '2026-04-01' AND '2026-04-28') AS april_revenue,
    (SELECT COUNT(*)
     FROM Inventory_Transaction it
     WHERE it.transaction_type = 'SALE'
       AND it.transaction_date BETWEEN '2026-04-01' AND '2026-04-28') AS april_sale_transactions,
    '2026-04-01'                                        AS period_start,
    '2026-04-28'                                        AS period_end
FROM Product p;

-- ============================================================
-- QUERY 10: Dead Stock Alert
-- Products with zero profit AND still in stock — no sales activity.
-- ============================================================
SELECT
    p.product_name,
    ss.site_name                                    AS storage_unit,
    p.product_quantity                              AS qty_in_stock,
    ROUND(p.product_quantity * p.cost, 2)           AS capital_at_risk,
    DATEDIFF(CURDATE(), p.date_added)               AS days_sitting
FROM Product p
JOIN Storage_Site ss ON ss.site_id = p.site_id
WHERE p.status IN ('IN_STOCK', 'RESERVED')
  AND p.profit = 0.00
ORDER BY capital_at_risk DESC;
