# Inventory Storage Database

This folder contains my database portion of the CS 5/7330 group project.
The original ER diagram used a table named `Transaction`, but I renamed it to
`Inventory_Transaction` because `TRANSACTION` is a SQL keyword.

## Files

Run the files in this order:

1. `01_create_database.sql`
2. `02_create_tables.sql`
3. `03_seed_data.sql`
4. `04_test_queries.sql`

Example:

```bash
mysql -u your_username -p < database/01_create_database.sql
mysql -u your_username -p < database/02_create_tables.sql
mysql -u your_username -p < database/03_seed_data.sql
mysql -u your_username -p < database/04_test_queries.sql
```

If you are already inside this folder, leave off `database/` in those commands.

The database name is `inventory_storage_db`.

## Tables

### Storage_Site

Stores physical locations where inventory can be kept.

Important rules:

- `site_id` is the primary key.
- `site_name`, `city`, and `state` are required.
- `state` must be a two-letter uppercase abbreviation.
- The same site name cannot be duplicated in the same city and state.

### Source_or_Supplier

Stores where products come from, such as suppliers, auctions, donations, or
customer returns.

Important rules:

- `source_id` is the primary key.
- `source_name` is required and unique.
- `source_type` must be one of the allowed source categories.

### Product

Stores the current product record and current inventory quantity.

Important rules:

- `product_id` is the primary key.
- Each product belongs to one `Storage_Site`.
- `condition` from the ER diagram is named `product_condition` to avoid
  keyword-style confusion in SQL.
- `cost` and `product_quantity` cannot be negative.
- Sold products must have quantity `0` and a `date_sold`.
- In-stock and reserved products must have quantity greater than `0`.
- `date_sold` cannot be earlier than `date_added`.

### Purchase_or_Order

Stores purchase/order records that connect products to suppliers or sources.

Important rules:

- `purchase_id` is the primary key.
- Each row references one `Product` and one `Source_or_Supplier`.
- `purchase_quantity` must be greater than `0`.
- `unit_cost` cannot be negative.
- `total_cost` is generated automatically as `purchase_quantity * unit_cost`.

### Inventory_Transaction

Stores inventory movement history. This replaces the original ER diagram table
name `Transaction`.

Important rules:

- `transaction_id` is the primary key.
- Each row references one `Product`.
- `transaction_quantity` must be greater than `0`.
- `unit_price` cannot be negative.
- `SALE` rows must have a unit price greater than `0`.
- `total_amount` is generated automatically as `transaction_quantity * unit_price`.
- A small trigger blocks sales, transfers, or adjustments that would move out
  more units than the product currently has.

## Design Notes

The design stays intentionally simple:

- `Product.product_quantity` is the current quantity available.
- `Purchase_or_Order` records buying/ordering information.
- `Inventory_Transaction` records stock movements.
- Foreign keys prevent orphan products, purchases, and transactions.
- Generated columns prevent inconsistent totals.
- Check constraints and enums block invalid statuses, conditions, source types,
  quantities, prices, and dates.

For backend integration, William should read the database connection settings
from a config file and connect to `inventory_storage_db`. CRUD routes can map
directly to these five tables. For stock changes, the app should update
`Product.product_quantity` and insert a matching row into
`Inventory_Transaction`.

## Demo Validation

After running the setup and seed scripts, run `04_test_queries.sql`.

Useful checks:

- Row counts confirm that seed data loaded.
- Inventory by site confirms products join correctly to storage locations.
- Supplier purchase history confirms purchases join correctly to sources.
- Product transaction history confirms transactions join correctly to products.
- Generated-total checks should return zero rows.
- Foreign-key validation checks should return zero rows.
- Sold-product validation should return zero rows.

The bottom of `04_test_queries.sql` includes commented-out failure tests. Run
them one at a time if you want to prove the database rejects bad data, such as
an invalid state, nonexistent storage site, zero-price sale, or sale greater
than available inventory.
