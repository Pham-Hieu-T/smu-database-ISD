-- This is the core database schema
-- btw I renamed transaction to inventory_transaction to avoid any errors

USE inventory_storage_db;

SET SESSION sql_mode = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

SET FOREIGN_KEY_CHECKS = 0;
DROP TRIGGER IF EXISTS prevent_negative_inventory;
DROP TABLE IF EXISTS Inventory_Transaction;
DROP TABLE IF EXISTS Purchase_or_Order;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Source_or_Supplier;
DROP TABLE IF EXISTS Storage_Site;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE Storage_Site (
    site_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    site_name VARCHAR(100) NOT NULL,
    city VARCHAR(80) NOT NULL,
    state VARCHAR(2) NOT NULL,

    PRIMARY KEY (site_id),
    CONSTRAINT uq_storage_site_location UNIQUE (site_name, city, state),
    CONSTRAINT chk_storage_site_state CHECK (
        CHAR_LENGTH(state) = 2
        AND state REGEXP '^[A-Z]{2}$'
        AND BINARY state = BINARY UPPER(state)
    )
) ENGINE = InnoDB;

CREATE TABLE Source_or_Supplier (
    source_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    source_name VARCHAR(120) NOT NULL,
    source_type ENUM('SUPPLIER', 'DONOR', 'AUCTION', 'CUSTOMER_RETURN', 'OTHER') NOT NULL,

    PRIMARY KEY (source_id),
    CONSTRAINT uq_source_name UNIQUE (source_name),
    CONSTRAINT chk_source_type CHECK (
        source_type IN ('SUPPLIER', 'DONOR', 'AUCTION', 'CUSTOMER_RETURN', 'OTHER')
    )
) ENGINE = InnoDB;

CREATE TABLE Product (
    product_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    product_name VARCHAR(120) NOT NULL,
    status ENUM('IN_STOCK', 'OUT_OF_STOCK', 'RESERVED', 'SOLD', 'DISCONTINUED') NOT NULL DEFAULT 'OUT_OF_STOCK',
    cost DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    profit DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    product_condition ENUM('NEW', 'GOOD', 'FAIR', 'POOR', 'DAMAGED') NOT NULL DEFAULT 'GOOD',
    date_added DATE NOT NULL,
    date_sold DATE NULL,
    product_quantity INT UNSIGNED NOT NULL DEFAULT 0,
    site_id INT UNSIGNED NOT NULL,

    PRIMARY KEY (product_id),
    INDEX idx_product_site_id (site_id),
    INDEX idx_product_status (status),
    INDEX idx_product_name (product_name),
    CONSTRAINT fk_product_storage_site
        FOREIGN KEY (site_id)
        REFERENCES Storage_Site (site_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_product_cost CHECK (cost >= 0),
    CONSTRAINT chk_product_quantity CHECK (product_quantity >= 0),
    CONSTRAINT chk_product_condition CHECK (
        product_condition IN ('NEW', 'GOOD', 'FAIR', 'POOR', 'DAMAGED')
    ),
    CONSTRAINT chk_product_status CHECK (
        status IN ('IN_STOCK', 'OUT_OF_STOCK', 'RESERVED', 'SOLD', 'DISCONTINUED')
    ),
    CONSTRAINT chk_product_sold_date CHECK (
        date_sold IS NULL OR date_sold >= date_added
    ),
    CONSTRAINT chk_product_status_quantity CHECK (
        (status IN ('IN_STOCK', 'RESERVED') AND product_quantity > 0 AND date_sold IS NULL)
        OR (status = 'OUT_OF_STOCK' AND product_quantity = 0 AND date_sold IS NULL)
        OR (status = 'SOLD' AND product_quantity = 0 AND date_sold IS NOT NULL)
        OR (status = 'DISCONTINUED' AND date_sold IS NULL)
    )
) ENGINE = InnoDB;

CREATE TABLE Purchase_or_Order (
    purchase_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    purchase_date DATE NOT NULL,
    purchase_quantity INT UNSIGNED NOT NULL,
    unit_cost DECIMAL(10,2) NOT NULL,
    total_cost DECIMAL(10,2) GENERATED ALWAYS AS (purchase_quantity * unit_cost) STORED,
    product_id INT UNSIGNED NOT NULL,
    source_id INT UNSIGNED NOT NULL,

    PRIMARY KEY (purchase_id),
    INDEX idx_purchase_product_id (product_id),
    INDEX idx_purchase_source_id (source_id),
    INDEX idx_purchase_date (purchase_date),
    CONSTRAINT fk_purchase_product
        FOREIGN KEY (product_id)
        REFERENCES Product (product_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_purchase_source
        FOREIGN KEY (source_id)
        REFERENCES Source_or_Supplier (source_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_purchase_quantity CHECK (purchase_quantity > 0),
    CONSTRAINT chk_purchase_unit_cost CHECK (unit_cost >= 0)
) ENGINE = InnoDB;

CREATE TABLE Inventory_Transaction (
    transaction_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    transaction_date DATE NOT NULL,
    transaction_type ENUM(
        'PURCHASE',
        'SALE',
        'TRANSFER_IN',
        'TRANSFER_OUT',
        'ADJUSTMENT_IN',
        'ADJUSTMENT_OUT',
        'RETURN'
    ) NOT NULL,
    transaction_quantity INT UNSIGNED NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total_amount DECIMAL(10,2) GENERATED ALWAYS AS (transaction_quantity * unit_price) STORED,
    product_id INT UNSIGNED NOT NULL,

    PRIMARY KEY (transaction_id),
    INDEX idx_transaction_product_id (product_id),
    INDEX idx_transaction_date (transaction_date),
    INDEX idx_transaction_type (transaction_type),
    CONSTRAINT fk_transaction_product
        FOREIGN KEY (product_id)
        REFERENCES Product (product_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_transaction_type CHECK (
        transaction_type IN (
            'PURCHASE',
            'SALE',
            'TRANSFER_IN',
            'TRANSFER_OUT',
            'ADJUSTMENT_IN',
            'ADJUSTMENT_OUT',
            'RETURN'
        )
    ),
    CONSTRAINT chk_transaction_quantity CHECK (transaction_quantity > 0),
    CONSTRAINT chk_transaction_unit_price CHECK (unit_price >= 0),
    CONSTRAINT chk_sale_has_price CHECK (
        transaction_type <> 'SALE' OR unit_price > 0
    )
) ENGINE = InnoDB;

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
