# Inventory Storage Database

This folder contains the SQL layer for the CS 5/7330 group project — an inventory and storage tracking system built for an Amazon reselling business operating out of three physical storage units in Plano, TX.

The original ER diagram used a table named `Transaction`, but it was renamed to `Inventory_Transaction` because `TRANSACTION` is a reserved SQL keyword.

## Files

Run the files in this order:

1. `01_create_database.sql` — creates the `inventory_storage_db` database
2. `02_create_tables.sql` — defines all five tables, constraints, and the trigger
3. `03_seed_data.sql` — loads real business data (50 products, 210 units, 65 sales, April 2026)
4. `04_test_queries.sql` — validation checks and demo queries to confirm setup
5. `05_queries.sql` — ten business queries covering inventory, profit, aging, and financials

```bash
mysql -u your_username -p < sql/01_create_database.sql
mysql -u your_username -p < sql/02_create_tables.sql
mysql -u your_username -p < sql/03_seed_data.sql
mysql -u your_username -p < sql/04_test_queries.sql
mysql -u your_username -p < sql/05_queries.sql
```

If you are already inside the `sql/` folder, omit `sql/` from those paths.

The database name is `inventory_storage_db`.

---

## Tables

### Storage_Site

Stores physical locations where inventory can be kept.

- `site_id` is the primary key.
- `site_name`, `city`, and `state` are required.
- `state` must be a two-letter uppercase abbreviation.
- The same site name cannot be duplicated in the same city and state.

### Source_or_Supplier

Stores where products come from — suppliers, auctions, donations, or customer returns.

- `source_id` is the primary key.
- `source_name` is required and unique.
- `source_type` must be one of the allowed source categories.

### Product

Stores the current product record and inventory quantity.

- `product_id` is the primary key.
- Each product belongs to one `Storage_Site`.
- `condition` from the ER diagram is named `product_condition` to avoid keyword-style confusion.
- `cost` and `product_quantity` cannot be negative.
- Sold products must have quantity `0` and a `date_sold`.
- In-stock and reserved products must have quantity greater than `0`.
- `date_sold` cannot be earlier than `date_added`.

### Purchase_or_Order

Stores purchase records linking products to their source or supplier.

- `purchase_id` is the primary key.
- Each row references one `Product` and one `Source_or_Supplier`.
- `purchase_quantity` must be greater than `0`.
- `unit_cost` cannot be negative.
- `total_cost` is a generated column computed automatically as `purchase_quantity * unit_cost`.

### Inventory_Transaction

Stores all inventory movement history. Replaces the original ER diagram table `Transaction`.

- `transaction_id` is the primary key.
- Each row references one `Product`.
- `transaction_quantity` must be greater than `0`.
- `unit_price` cannot be negative.
- `SALE` rows must have a unit price greater than `0`.
- `total_amount` is a generated column computed automatically as `transaction_quantity * unit_price`.
- A trigger (`prevent_negative_inventory`) blocks any sale, transfer, or adjustment that would reduce quantity below zero.

---

## Seed Data (`03_seed_data.sql`)

The seed data reflects real April 2026 inventory from an Amazon reselling operation:

- **3 storage units** — Unit 3577 (TVs/large displays), Unit G76 (audio equipment), Unit 3575 (misc electronics), all in Plano, TX
- **1 supplier** — Direct Supply (auction source)
- **50 products** across all three units
- **210 total units** purchased
- **65 sale transactions** recorded April 1–28, 2026

The file drops and recreates the `prevent_negative_inventory` trigger around the INSERT block so that bulk seed data loads without false constraint violations.

---

## Business Queries (`05_queries.sql`)

Ten queries written to answer real operational questions:

| # | Query | Business Question |
|---|-------|-------------------|
| 1 | Inventory by Storage Site | What products are at each location and what is their total value? |
| 2 | Site-Level Inventory Summary | Which storage unit has the most capital tied up in it? |
| 3 | Product Status Report | How many product types and units are in each status category? |
| 4 | Inventory Aging Report | Which products have been sitting over 30 days? |
| 5 | Supplier Purchase History | How many units were bought from each supplier and at what total cost? |
| 6 | Full Inventory Transaction History | What is the complete event log for every product? |
| 7 | Sales History with Profit | For every April sale, what was the profit per unit and total? |
| 8 | Cost and Profit Summary | Which products generated the most profit and what were their margins? |
| 9 | Overall Financial Summary | What is the complete April 2026 financial picture in one view? |
| 10 | Dead Stock Alert | Which products have never sold and how much capital is frozen in them? |

SQL concepts used: `JOIN`, `LEFT JOIN`, `GROUP BY`, `CASE WHEN`, `DATEDIFF`, `CURDATE()`, subqueries, `BETWEEN`, `COUNT`, `SUM`, `ROUND`, `CONCAT`.

---

## Design Notes

- `Product.product_quantity` is the current on-hand quantity.
- `Purchase_or_Order` records acquisition details per product.
- `Inventory_Transaction` records all stock movements (purchases, sales, transfers, adjustments).
- Foreign keys prevent orphaned products, purchases, and transactions.
- Generated columns prevent inconsistent totals across related fields.
- Check constraints and enums block invalid statuses, conditions, source types, quantities, prices, and dates.

For backend integration, CRUD routes can map directly to these five tables. For stock changes, the app should update `Product.product_quantity` and insert a matching row into `Inventory_Transaction`.

---

## Demo Validation

After running the setup and seed scripts, run `04_test_queries.sql`:

- Row counts confirm seed data loaded correctly.
- Inventory by site confirms products join to storage locations.
- Supplier purchase history confirms purchases join to sources.
- Product transaction history confirms transactions join to products.
- Generated-total checks should return **zero rows**.
- Foreign-key validation checks should return **zero rows**.
- Sold-product validation should return **zero rows**.

The bottom of `04_test_queries.sql` includes commented-out failure tests. Run them one at a time to prove the database rejects bad data: invalid state format, nonexistent storage site, zero-price sale, or sale exceeding available inventory.
