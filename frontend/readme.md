# Inventory Frontend

HTML/CSS/JS frontend for the project.

## Run

From this folder:

```bash
python3 -m http.server 5173
```

Open:

```text
http://localhost:5173
```

For the final standalone project, serve this frontend from the backend app and expose the backend routes under the same origin:

```text
/api
```

The browser UI does not expose database settings or direct API configuration to the user.

## API

The frontend calls these routes under `/api`. For example, `GET /products` below means the browser calls `GET /api/products`.

Responses:

```json
{ "data": [] }
```

Errors:

```json
{ "error": { "message": "Validation failed", "fields": { "field_name": "Message" } } }
```

Required routes, relative to `/api`:

```text
GET /health
GET /storage-sites
POST /storage-sites
PUT /storage-sites/:site_id
DELETE /storage-sites/:site_id

GET /sources
POST /sources
PUT /sources/:source_id
DELETE /sources/:source_id

GET /products
POST /products
PUT /products/:product_id
DELETE /products/:product_id

GET /purchases
POST /purchases
PUT /purchases/:purchase_id
DELETE /purchases/:purchase_id

GET /transactions
POST /transactions
PUT /transactions/:transaction_id
DELETE /transactions/:transaction_id

GET /reports/inventory-by-site
GET /reports/site-summary
GET /reports/status-summary
GET /reports/aging
GET /reports/supplier-history
GET /reports/transaction-history
GET /reports/sales-profit
GET /reports/profit-summary
GET /reports/financial-summary
GET /reports/dead-stock
```

Use DB-aligned `snake_case` JSON keys. Generated database columns such as `total_cost` and `total_amount` should be returned by `GET` routes but are not submitted by the frontend forms.

During local frontend-only development, the static page will show the backend as offline unless a backend is also serving `/api`. For demo/submission, prefer one backend process that serves both the static frontend and `/api` routes so users never need to configure API access manually.
