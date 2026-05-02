-- This is just some sample data that I needed for testing and that y'all can use
-- for testing as well should you need it.

USE inventory_storage_db;

SET SESSION sql_mode = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE Inventory_Transaction;
TRUNCATE TABLE Purchase_or_Order;
TRUNCATE TABLE Product;
TRUNCATE TABLE Source_or_Supplier;
TRUNCATE TABLE Storage_Site;
SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO Storage_Site (site_id, site_name, city, state) VALUES
    (1, 'North Warehouse', 'Dallas', 'TX'),
    (2, 'Campus Storage', 'Richardson', 'TX'),
    (3, 'Overflow Unit', 'Plano', 'TX');

INSERT INTO Source_or_Supplier (source_id, source_name, source_type) VALUES
    (1, 'Acme Office Supply', 'SUPPLIER'),
    (2, 'Metro Liquidators', 'AUCTION'),
    (3, 'Community Donation Center', 'DONOR'),
    (4, 'Customer Return Desk', 'CUSTOMER_RETURN'),
    (5, 'General Misc Source', 'OTHER');

INSERT INTO Product (
    product_id,
    product_name,
    status,
    cost,
    profit,
    product_condition,
    date_added,
    date_sold,
    product_quantity,
    site_id
) VALUES
    (1, 'Ergonomic Office Chair', 'IN_STOCK', 35.00, 0.00, 'GOOD', '2026-04-01', NULL, 20, 1),
    (2, 'Laptop Stand', 'IN_STOCK', 12.00, 0.00, 'NEW', '2026-04-02', NULL, 15, 1),
    (3, 'Standing Desk', 'IN_STOCK', 110.00, 0.00, 'GOOD', '2026-04-03', NULL, 3, 2),
    (4, 'Packing Box Bundle', 'IN_STOCK', 1.25, 0.00, 'NEW', '2026-04-05', NULL, 100, 3),
    (5, 'Computer Monitor', 'IN_STOCK', 85.00, 0.00, 'FAIR', '2026-04-07', NULL, 8, 2),
    (6, 'Damaged File Cabinet', 'DISCONTINUED', 10.00, 0.00, 'DAMAGED', '2026-04-08', NULL, 0, 3);

INSERT INTO Purchase_or_Order (
    purchase_id,
    purchase_date,
    purchase_quantity,
    unit_cost,
    product_id,
    source_id
) VALUES
    (1, '2026-04-01', 20, 35.00, 1, 1),
    (2, '2026-04-02', 15, 12.00, 2, 1),
    (3, '2026-04-03', 3, 110.00, 3, 2),
    (4, '2026-04-05', 100, 1.25, 4, 1),
    (5, '2026-04-07', 8, 85.00, 5, 2),
    (6, '2026-04-08', 1, 10.00, 6, 3);

INSERT INTO Inventory_Transaction (
    transaction_id,
    transaction_date,
    transaction_type,
    transaction_quantity,
    unit_price,
    product_id
) VALUES
    (1, '2026-04-01', 'PURCHASE', 20, 35.00, 1),
    (2, '2026-04-02', 'PURCHASE', 15, 12.00, 2),
    (3, '2026-04-03', 'PURCHASE', 3, 110.00, 3),
    (4, '2026-04-05', 'PURCHASE', 100, 1.25, 4),
    (5, '2026-04-07', 'PURCHASE', 8, 85.00, 5),
    (6, '2026-04-10', 'SALE', 4, 65.00, 1),
    (7, '2026-04-12', 'SALE', 2, 28.00, 2),
    (8, '2026-04-18', 'SALE', 3, 210.00, 3),
    (9, '2026-04-19', 'TRANSFER_OUT', 25, 0.00, 4),
    (10, '2026-04-20', 'ADJUSTMENT_OUT', 1, 0.00, 5),
    (11, '2026-04-22', 'RETURN', 1, 0.00, 1);

UPDATE Product
SET product_quantity = 17, profit = 120.00
WHERE product_id = 1;

UPDATE Product
SET product_quantity = 13, profit = 32.00
WHERE product_id = 2;

UPDATE Product
SET status = 'SOLD', product_quantity = 0, profit = 300.00, date_sold = '2026-04-18'
WHERE product_id = 3;

UPDATE Product
SET product_quantity = 75
WHERE product_id = 4;

UPDATE Product
SET product_quantity = 7
WHERE product_id = 5;
