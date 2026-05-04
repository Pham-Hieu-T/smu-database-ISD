-- Some demo and report queries and validation checks

USE inventory_storage_db;

-- Quick row counts for setup verification
SELECT 'Storage_Site' AS table_name, COUNT(*) AS row_count FROM Storage_Site
UNION ALL
SELECT 'Source_or_Supplier', COUNT(*) FROM Source_or_Supplier
UNION ALL
SELECT 'Product', COUNT(*) FROM Product
UNION ALL
SELECT 'Purchase_or_Order', COUNT(*) FROM Purchase_or_Order
UNION ALL
SELECT 'Inventory_Transaction', COUNT(*) FROM Inventory_Transaction;

-- Inventory by site
SELECT
    ss.site_name,
    ss.city,
    ss.state,
    p.product_id,
    p.product_name,
    p.status,
    p.product_condition,
    p.product_quantity,
    p.cost,
    (p.product_quantity * p.cost) AS estimated_inventory_value
FROM Storage_Site AS ss
JOIN Product AS p
    ON p.site_id = ss.site_id
ORDER BY ss.site_name, p.product_name;

-- Site level inventory summary
SELECT
    ss.site_name,
    COUNT(p.product_id) AS product_count,
    SUM(p.product_quantity) AS total_units,
    SUM(p.product_quantity * p.cost) AS estimated_inventory_value
FROM Storage_Site AS ss
LEFT JOIN Product AS p
    ON p.site_id = ss.site_id
GROUP BY ss.site_id, ss.site_name
ORDER BY ss.site_name;

-- Product status summary
SELECT
    status,
    COUNT(*) AS product_count,
    SUM(product_quantity) AS total_units
FROM Product
GROUP BY status
ORDER BY status;

-- Supplier/source purchase history
SELECT
    s.source_name,
    s.source_type,
    COUNT(po.purchase_id) AS purchase_count,
    COALESCE(SUM(po.purchase_quantity), 0) AS total_units_purchased,
    COALESCE(SUM(po.total_cost), 0.00) AS total_purchase_cost
FROM Source_or_Supplier AS s
LEFT JOIN Purchase_or_Order AS po
    ON po.source_id = s.source_id
GROUP BY s.source_id, s.source_name, s.source_type
ORDER BY total_purchase_cost DESC, s.source_name;

-- Product transaction history
SELECT
    p.product_id,
    p.product_name,
    it.transaction_date,
    it.transaction_type,
    it.transaction_quantity,
    it.unit_price,
    it.total_amount
FROM Product AS p
JOIN Inventory_Transaction AS it
    ON it.product_id = p.product_id
ORDER BY p.product_name, it.transaction_date, it.transaction_id;

-- Cost and profit summary
SELECT
    p.product_name,
    p.status,
    p.product_quantity,
    p.cost AS unit_cost,
    (p.product_quantity * p.cost) AS remaining_cost_value,
    p.profit AS recorded_profit
FROM Product AS p
ORDER BY recorded_profit DESC, p.product_name;

-- Generated total validation. Both queries should return zero rows
SELECT
    purchase_id,
    purchase_quantity,
    unit_cost,
    total_cost
FROM Purchase_or_Order
WHERE total_cost <> (purchase_quantity * unit_cost);

SELECT
    transaction_id,
    transaction_quantity,
    unit_price,
    total_amount
FROM Inventory_Transaction
WHERE total_amount <> (transaction_quantity * unit_price);

-- Foreign key validation. Both queries should return zero rows
SELECT p.*
FROM Product AS p
LEFT JOIN Storage_Site AS ss
    ON ss.site_id = p.site_id
WHERE ss.site_id IS NULL;

SELECT it.*
FROM Inventory_Transaction AS it
LEFT JOIN Product AS p
    ON p.product_id = it.product_id
WHERE p.product_id IS NULL;

-- Sold-product validation. This should return zero rows
SELECT *
FROM Product
WHERE status = 'SOLD'
  AND (product_quantity <> 0 OR date_sold IS NULL);

SELECT
    p.product_id,
    p.product_name,
    p.product_quantity,
    COALESCE(SUM(
        CASE
            WHEN it.transaction_type IN ('PURCHASE', 'TRANSFER_IN', 'ADJUSTMENT_IN', 'RETURN')
                THEN it.transaction_quantity
            WHEN it.transaction_type IN ('SALE', 'TRANSFER_OUT', 'ADJUSTMENT_OUT')
                THEN -it.transaction_quantity
            ELSE 0
        END
    ), 0) AS quantity_from_transactions
FROM Product AS p
LEFT JOIN Inventory_Transaction AS it
    ON it.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.product_quantity
HAVING p.product_quantity <> quantity_from_transactions;

SELECT
    p.product_id,
    p.product_name,
    p.profit,
    ROUND(COALESCE(SUM(
        CASE
            WHEN it.transaction_type = 'SALE'
                THEN (it.unit_price - p.cost) * it.transaction_quantity
            ELSE 0
        END
    ), 0), 2) AS profit_from_sales
FROM Product AS p
LEFT JOIN Inventory_Transaction AS it
    ON it.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.profit
HAVING ABS(p.profit - profit_from_sales) > 0.01;

-- These are some tests to test things that I think he would try to break
-- Uncomment and run these one at a time only if you want to prove constraints work
--
-- Bad state format:
-- INSERT INTO Storage_Site (site_name, city, state)
-- VALUES ('Broken Site', 'Dallas', 'tx');
--
-- Product assigned to a storage site that does not exist:
-- INSERT INTO Product (
--     product_name, status, cost, profit, product_condition,
--     date_added, date_sold, product_quantity, site_id
-- ) VALUES (
--     'Invalid Product', 'OUT_OF_STOCK', 1.00, 0.00, 'GOOD',
--     '2026-04-01', NULL, 0, 999
-- );
--
-- Sale with no sale price:
-- INSERT INTO Inventory_Transaction (
--     transaction_date, transaction_type, transaction_quantity, unit_price, product_id
-- ) VALUES (
--     '2026-04-25', 'SALE', 1, 0.00, 1
-- );
--
-- Sale greater than available inventory:
-- INSERT INTO Inventory_Transaction (
--     transaction_date, transaction_type, transaction_quantity, unit_price, product_id
-- ) VALUES (
--     '2026-04-25', 'SALE', 999, 65.00, 1
-- );
