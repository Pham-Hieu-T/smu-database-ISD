# Backend Handoff

Frontend is ready in `frontend/`. The backend still needs to connect that GUI to MySQL.

## What the frontend does

- Shows pages for dashboard, products, storage sites, sources, purchases, transactions, and reports.
- Sends all backend requests to `/api`.
- Shows a offline message when the backend is not running.

## How to preview the frontend

From the repo root:

```bash
cd frontend
python3 -m http.server 5173
```

Open:

```text
http://localhost:5173
```

This is frontend preview only. It will show backend offline until `/api` exists.

## Final backend behavior

For the demo, we should run one backend app that serves both, that we can do later:

- static files from `frontend/`
- JSON routes under `/api`


## Database config


Read connection settings from a backend-only config file. Use `db_config.example.json` as the template:

```json
{
  "host": "localhost",
  "port": 3306,
  "user": "root",
  "password": "",
  "database": "inventory_storage_db"
}
```


## Required response format

Successful response:

```json
{ "data": [] }
```

Single-row responses can also use the same wrapper:

```json
{ "data": { "product_id": 1, "product_name": "Example" } }
```

Error response:

```json
{ "error": { "message": "Something went wrong" } }
```

## Required API routes

Health:

```text
GET /api/health
```

CRUD:

```text
GET /api/storage-sites
POST /api/storage-sites
PUT /api/storage-sites/:site_id
DELETE /api/storage-sites/:site_id

GET /api/sources
POST /api/sources
PUT /api/sources/:source_id
DELETE /api/sources/:source_id

GET /api/products
POST /api/products
PUT /api/products/:product_id
DELETE /api/products/:product_id

GET /api/purchases
POST /api/purchases
PUT /api/purchases/:purchase_id
DELETE /api/purchases/:purchase_id

GET /api/transactions
POST /api/transactions
PUT /api/transactions/:transaction_id
DELETE /api/transactions/:transaction_id
```

Reports:

```text
GET /api/reports/inventory-by-site
GET /api/reports/site-summary
GET /api/reports/status-summary
GET /api/reports/aging
GET /api/reports/supplier-history
GET /api/reports/transaction-history
GET /api/reports/sales-profit
GET /api/reports/profit-summary
GET /api/reports/financial-summary
GET /api/reports/dead-stock
```

## Important backend notes

- Use `snake_case` JSON keys that match the database columns.
- Return generated columns like `total_cost` and `total_amount` on GET routes.
- The frontend does not submit generated columns in forms.
- For transactions that change stock, update `Product.product_quantity` and insert the matching `Inventory_Transaction` row.
- Let MySQL constraints and the `prevent_negative_inventory` trigger reject invalid data, then return a simple JSON error message.
- Reports should map to the SQL in `sql/05_queries.sql`.
