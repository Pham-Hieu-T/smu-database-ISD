import json
from pathlib import Path

import mysql.connector
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

# -------------------------
# Config + DB
# -------------------------
BACKEND_DIR = Path(__file__).resolve().parent
PROJECT_DIR = BACKEND_DIR.parent
CONFIG_FILE = BACKEND_DIR / "db_config.json"
FRONTEND_DIR = PROJECT_DIR / "frontend"

def get_connection():
    with open(CONFIG_FILE, encoding="utf-8") as f:
        config = json.load(f)
    return mysql.connector.connect(**config)

def success(data):
    return {"data": data}

def db_error(err):
    return JSONResponse(
        status_code=400,
        content={"error": {"message": str(err)}}
    )

# -------------------------
# App
# -------------------------
app = FastAPI(docs_url=None, redoc_url=None, openapi_url=None)

# -------------------------
# Health
# -------------------------
@app.get("/api/health")
def health():
    conn = None
    cur = None
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("SELECT 1")
        cur.fetchone()
        return success({"server": "ok", "database": "ok"})
    except mysql.connector.Error as e:
        return JSONResponse(
            status_code=503,
            content={"error": {"message": f"Database unavailable: {e}"}}
        )
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

# -------------------------
# STORAGE SITES
# -------------------------
@app.get("/api/storage-sites")
def get_sites():
    conn = get_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute("SELECT site_id, site_name, city, state FROM Storage_Site")
    return success(cur.fetchall())

@app.post("/api/storage-sites")
def create_site(body: dict):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            "INSERT INTO Storage_Site (site_name, city, state) VALUES (%s, %s, %s)",
            (body["site_name"], body.get("city"), body.get("state"))
        )
        conn.commit()
        return success({"site_id": cur.lastrowid})
    except mysql.connector.Error as e:
        return db_error(e)

@app.put("/api/storage-sites/{site_id}")
def update_site(site_id: int, body: dict):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            "UPDATE Storage_Site SET site_name=%s, city=%s, state=%s WHERE site_id=%s",
            (body["site_name"], body.get("city"), body.get("state"), site_id)
        )
        conn.commit()
        return success({"updated": cur.rowcount})
    except mysql.connector.Error as e:
        return db_error(e)

@app.delete("/api/storage-sites/{site_id}")
def delete_site(site_id: int):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute("DELETE FROM Storage_Site WHERE site_id=%s", (site_id,))
        conn.commit()
        return success({"deleted": cur.rowcount})
    except mysql.connector.Error as e:
        return db_error(e)

# -------------------------
# SOURCES
# -------------------------
@app.get("/api/sources")
def get_sources():
    conn = get_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute("SELECT source_id, source_name, source_type FROM Source_or_Supplier")
    return success(cur.fetchall())

@app.post("/api/sources")
def create_source(body: dict):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            "INSERT INTO Source_or_Supplier (source_name, source_type) VALUES (%s, %s)",
            (body["source_name"], body.get("source_type"))
        )
        conn.commit()
        return success({"source_id": cur.lastrowid})
    except mysql.connector.Error as e:
        return db_error(e)

@app.put("/api/sources/{source_id}")
def update_source(source_id: int, body: dict):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            "UPDATE Source_or_Supplier SET source_name=%s, source_type=%s WHERE source_id=%s",
            (body["source_name"], body.get("source_type"), source_id)
        )
        conn.commit()
        return success({"updated": cur.rowcount})
    except mysql.connector.Error as e:
        return db_error(e)

@app.delete("/api/sources/{source_id}")
def delete_source(source_id: int):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute("DELETE FROM Source_or_Supplier WHERE source_id=%s", (source_id,))
        conn.commit()
        return success({"deleted": cur.rowcount})
    except mysql.connector.Error as e:
        return db_error(e)

# -------------------------
# PRODUCTS
# -------------------------
@app.get("/api/products")
def get_products():
    conn = get_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute("""
        SELECT 
            product_id, product_name, status, product_condition, 
            product_quantity, cost, profit, date_added, date_sold, site_id
        FROM Product
    """)
    return success(cur.fetchall())

@app.post("/api/products")
def create_product(body: dict):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """INSERT INTO Product 
               (product_name, status, product_condition, product_quantity, cost, profit, date_added, date_sold, site_id) 
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)""",
            (
                body["product_name"], 
                body.get("status", "OUT_OF_STOCK"), 
                body.get("product_condition", "GOOD"),
                body.get("product_quantity", 0), 
                body.get("cost", 0), 
                body.get("profit", 0),
                body.get("date_added"), 
                body.get("date_sold"), 
                body.get("site_id", 1)
            )
        )
        conn.commit()
        return success({"product_id": cur.lastrowid})
    except mysql.connector.Error as e:
        return db_error(e)

@app.put("/api/products/{product_id}")
def update_product(product_id: int, body: dict):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """UPDATE Product 
               SET product_name=%s, status=%s, product_condition=%s, product_quantity=%s, 
                   cost=%s, profit=%s, date_added=%s, date_sold=%s, site_id=%s 
               WHERE product_id=%s""",
            (
                body["product_name"], 
                body.get("status"), 
                body.get("product_condition"),
                body.get("product_quantity"), 
                body.get("cost"), 
                body.get("profit"),
                body.get("date_added"), 
                body.get("date_sold"), 
                body.get("site_id"),
                product_id
            )
        )
        conn.commit()
        return success({"updated": cur.rowcount})
    except mysql.connector.Error as e:
        return db_error(e)

@app.delete("/api/products/{product_id}")
def delete_product(product_id: int):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute("DELETE FROM Product WHERE product_id=%s", (product_id,))
        conn.commit()
        return success({"deleted": cur.rowcount})
    except mysql.connector.Error as e:
        return db_error(e)

# -------------------------
# PURCHASES
# -------------------------
@app.get("/api/purchases")
def get_purchases():
    conn = get_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute("""
        SELECT purchase_id, purchase_date, purchase_quantity, unit_cost, total_cost, product_id, source_id
        FROM Purchase_or_Order
    """)
    return success(cur.fetchall())

@app.post("/api/purchases")
def create_purchase(body: dict):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """INSERT INTO Purchase_or_Order 
               (purchase_date, purchase_quantity, unit_cost, product_id, source_id) 
               VALUES (%s, %s, %s, %s, %s)""",
            (
                body.get("purchase_date"), 
                body.get("purchase_quantity"), 
                body.get("unit_cost"),
                body.get("product_id"), 
                body.get("source_id")
            )
        )
        conn.commit()
        return success({"purchase_id": cur.lastrowid})
    except mysql.connector.Error as e:
        return db_error(e)

@app.put("/api/purchases/{purchase_id}")
def update_purchase(purchase_id: int, body: dict):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """UPDATE Purchase_or_Order 
               SET purchase_date=%s, purchase_quantity=%s, unit_cost=%s, product_id=%s, source_id=%s 
               WHERE purchase_id=%s""",
            (
                body.get("purchase_date"), 
                body.get("purchase_quantity"), 
                body.get("unit_cost"),
                body.get("product_id"), 
                body.get("source_id"),
                purchase_id
            )
        )
        conn.commit()
        return success({"updated": cur.rowcount})
    except mysql.connector.Error as e:
        return db_error(e)

@app.delete("/api/purchases/{purchase_id}")
def delete_purchase(purchase_id: int):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute("DELETE FROM Purchase_or_Order WHERE purchase_id=%s", (purchase_id,))
        conn.commit()
        return success({"deleted": cur.rowcount})
    except mysql.connector.Error as e:
        return db_error(e)

# -------------------------
# TRANSACTIONS
# -------------------------
@app.get("/api/transactions")
def get_transactions():
    conn = get_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute("""
        SELECT 
            transaction_id, transaction_date, transaction_type, 
            transaction_quantity, unit_price, total_amount, product_id
        FROM Inventory_Transaction
    """)
    return success(cur.fetchall())

@app.post("/api/transactions")
def create_transaction(body: dict):
    conn = get_connection()
    cur = conn.cursor()
    try:
        product_id = body["product_id"]
        qty = body.get("transaction_quantity", body.get("quantity", 0))
        unit_price = body.get("unit_price", 0)

        # update inventory based on transaction type
        if body["transaction_type"] in ('SALE', 'TRANSFER_OUT', 'ADJUSTMENT_OUT'):
            cur.execute(
                "UPDATE Product SET product_quantity = product_quantity - %s WHERE product_id=%s",
                (qty, product_id)
            )
        else:
            cur.execute(
                "UPDATE Product SET product_quantity = product_quantity + %s WHERE product_id=%s",
                (qty, product_id)
            )

        # insert transaction
        cur.execute(
            """INSERT INTO Inventory_Transaction 
               (product_id, transaction_quantity, transaction_type, unit_price, transaction_date) 
               VALUES (%s, %s, %s, %s, %s)""",
            (product_id, qty, body["transaction_type"], unit_price, body.get("transaction_date"))
        )

        conn.commit()
        return success({"transaction_id": cur.lastrowid})

    except mysql.connector.Error as e:
        return db_error(e)

@app.put("/api/transactions/{transaction_id}")
def update_transaction(transaction_id: int, body: dict):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """UPDATE Inventory_Transaction 
               SET transaction_quantity=%s, transaction_type=%s, unit_price=%s, transaction_date=%s 
               WHERE transaction_id=%s""",
            (
                body.get("transaction_quantity"), 
                body.get("transaction_type"), 
                body.get("unit_price"),
                body.get("transaction_date"),
                transaction_id
            )
        )
        conn.commit()
        return success({"updated": cur.rowcount})
    except mysql.connector.Error as e:
        return db_error(e)

@app.delete("/api/transactions/{transaction_id}")
def delete_transaction(transaction_id: int):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute("DELETE FROM Inventory_Transaction WHERE transaction_id=%s", (transaction_id,))
        conn.commit()
        return success({"deleted": cur.rowcount})
    except mysql.connector.Error as e:
        return db_error(e)

# -------------------------
# REPORTS
# -------------------------
@app.get("/api/reports/inventory-by-site")
def report_inventory_by_site():
    conn = get_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute("""
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
        ORDER BY ss.site_name, p.product_name
    """)
    return success(cur.fetchall())

@app.get("/api/reports/site-summary")
def report_site_summary():
    conn = get_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute("""
        SELECT
            ss.site_name                                    AS storage_unit,
            COUNT(p.product_id)                             AS product_types,
            SUM(p.product_quantity)                         AS total_units,
            ROUND(SUM(p.product_quantity * p.cost), 2)      AS total_inventory_value
        FROM Storage_Site ss
        LEFT JOIN Product p ON p.site_id = ss.site_id
            AND p.status IN ('IN_STOCK', 'RESERVED')
        GROUP BY ss.site_id, ss.site_name
        ORDER BY total_inventory_value DESC
    """)
    return success(cur.fetchall())

@app.get("/api/reports/status-summary")
def report_status_summary():
    conn = get_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute("""
        SELECT
            status,
            COUNT(*)                                        AS product_count,
            SUM(product_quantity)                           AS units_remaining
        FROM Product
        GROUP BY status
        ORDER BY product_count DESC
    """)
    return success(cur.fetchall())

@app.get("/api/reports/aging")
def report_aging():
    conn = get_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute("""
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
        ORDER BY days_in_stock DESC
    """)
    return success(cur.fetchall())

@app.get("/api/reports/supplier-history")
def report_supplier_history():
    conn = get_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute("""
        SELECT
            s.source_name,
            s.source_type,
            COUNT(po.purchase_id)                           AS total_purchases,
            SUM(po.purchase_quantity)                       AS total_units_bought,
            ROUND(SUM(po.total_cost), 2)                    AS total_spent
        FROM Source_or_Supplier s
        LEFT JOIN Purchase_or_Order po ON po.source_id = s.source_id
        GROUP BY s.source_id, s.source_name, s.source_type
        ORDER BY total_spent DESC
    """)
    return success(cur.fetchall())

@app.get("/api/reports/transaction-history")
def report_transaction_history():
    conn = get_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute("""
        SELECT
            p.product_name,
            it.transaction_date,
            it.transaction_type,
            it.transaction_quantity                         AS qty,
            it.unit_price,
            it.total_amount
        FROM Product p
        JOIN Inventory_Transaction it ON it.product_id = p.product_id
        ORDER BY p.product_name, it.transaction_date, it.transaction_id
    """)
    return success(cur.fetchall())

@app.get("/api/reports/sales-profit")
def report_sales_profit():
    conn = get_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute("""
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
        ORDER BY it.transaction_date, p.product_name
    """)
    return success(cur.fetchall())

@app.get("/api/reports/profit-summary")
def report_profit_summary():
    conn = get_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute("""
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
        ORDER BY realized_profit DESC
    """)
    return success(cur.fetchall())

@app.get("/api/reports/financial-summary")
def report_financial_summary():
    conn = get_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute("""
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
        FROM Product p
    """)
    return success(cur.fetchall())

@app.get("/api/reports/dead-stock")
def report_dead_stock():
    conn = get_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute("""
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
        ORDER BY capital_at_risk DESC
    """)
    return success(cur.fetchall())

# -------------------------
# Serve frontend
# -------------------------
app.mount("/", StaticFiles(directory=str(FRONTEND_DIR), html=True), name="frontend")
