import json
import re
from datetime import date
from decimal import Decimal
from pathlib import Path
from typing import Callable, Literal

import mysql.connector
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

# -------------------------
# Config + DB
# -------------------------
BACKEND_DIR = Path(__file__).resolve().parent
PROJECT_DIR = BACKEND_DIR.parent
CONFIG_FILE = BACKEND_DIR / "db_config.json"
FRONTEND_DIR = PROJECT_DIR / "frontend"

STATUS_OPTIONS = {"IN_STOCK", "OUT_OF_STOCK", "RESERVED", "SOLD", "DISCONTINUED"}
CONDITION_OPTIONS = {"NEW", "GOOD", "FAIR", "POOR", "DAMAGED"}
SOURCE_OPTIONS = {"SUPPLIER", "DONOR", "AUCTION", "CUSTOMER_RETURN", "OTHER"}
TRANSACTION_OPTIONS = {
    "PURCHASE",
    "SALE",
    "TRANSFER_IN",
    "TRANSFER_OUT",
    "ADJUSTMENT_IN",
    "ADJUSTMENT_OUT",
    "RETURN",
}
INBOUND_TYPES = {"PURCHASE", "TRANSFER_IN", "ADJUSTMENT_IN", "RETURN"}
OUTBOUND_TYPES = {"SALE", "TRANSFER_OUT", "ADJUSTMENT_OUT"}
MONEY_UNIT = Decimal("0.01")
MONEY_MAX = Decimal("99999999.99")
PROFIT_MIN = Decimal("-99999999.99")

Status = Literal["IN_STOCK", "OUT_OF_STOCK", "RESERVED", "SOLD", "DISCONTINUED"]
Condition = Literal["NEW", "GOOD", "FAIR", "POOR", "DAMAGED"]
SourceType = Literal["SUPPLIER", "DONOR", "AUCTION", "CUSTOMER_RETURN", "OTHER"]
TransactionType = Literal[
    "PURCHASE",
    "SALE",
    "TRANSFER_IN",
    "TRANSFER_OUT",
    "ADJUSTMENT_IN",
    "ADJUSTMENT_OUT",
    "RETURN",
]


def get_connection():
    with open(CONFIG_FILE, encoding="utf-8") as f:
        config = json.load(f)
    return mysql.connector.connect(**config)


def success(data):
    return {"data": data}


def error_response(message, status_code=400):
    return JSONResponse(status_code=status_code, content={"error": {"message": message}})


def clean_db_message(err):
    message = str(err)
    errno = getattr(err, "errno", None)

    if "Not enough inventory" in message:
        return "Not enough inventory for this transaction."
    if errno == 1062:
        return "A record with the same unique value already exists."
    if errno == 1451:
        return "This record cannot be deleted because other records still reference it."
    if errno == 1452:
        return "The selected linked record does not exist."
    if errno in {1048, 1264, 1265, 1292, 1366, 1406, 3819}:
        return "Database rejected the value. Check field lengths, dates, and numbers."
    return "Database rejected the change. Check required fields and linked records."


def db_error(err):
    return error_response(clean_db_message(err))


class AppError(Exception):
    def __init__(self, message, status_code=400):
        super().__init__(message)
        self.message = message
        self.status_code = status_code


def close_db(cur=None, conn=None):
    if cur:
        cur.close()
    if conn:
        conn.close()


def rollback(conn):
    if conn:
        conn.rollback()


def db_read(work: Callable):
    conn = None
    cur = None
    try:
        conn = get_connection()
        cur = conn.cursor(dictionary=True)
        return success(work(cur))
    except mysql.connector.Error as e:
        return db_error(e)
    except Exception:
        return error_response("Request failed. Check the submitted values and try again.", 500)
    finally:
        close_db(cur, conn)


def db_write(work: Callable):
    conn = None
    cur = None
    try:
        conn = get_connection()
        conn.start_transaction()
        cur = conn.cursor(dictionary=True)
        data = work(cur)
        conn.commit()
        return success(data)
    except AppError as e:
        rollback(conn)
        return error_response(e.message, e.status_code)
    except mysql.connector.Error as e:
        rollback(conn)
        return db_error(e)
    except Exception:
        rollback(conn)
        return error_response("Request failed. No database changes were saved.", 500)
    finally:
        close_db(cur, conn)


def fetch_all(sql, params=()):
    return db_read(lambda cur: _fetch_all(cur, sql, params))


def _fetch_all(cur, sql, params=()):
    cur.execute(sql, params)
    return cur.fetchall()


def strip_required(value):
    if isinstance(value, str):
        value = value.strip()
    return value


def decimal_value(value):
    if isinstance(value, Decimal):
        return value
    if value is None:
        return Decimal("0.00")
    return Decimal(str(value))


def money(value):
    return decimal_value(value).quantize(MONEY_UNIT)


def first_validation_message(exc):
    errors = exc.errors()
    if not errors:
        return "Please check the form fields."

    first = errors[0]
    loc = [str(part) for part in first.get("loc", []) if part != "body"]
    field = loc[-1].replace("_", " ") if loc else "field"
    field_label = field.title()
    message = first.get("msg", "Invalid value.")
    error_type = first.get("type")
    context = first.get("ctx", {})

    if message.startswith("Value error, "):
        message = message.replace("Value error, ", "", 1)
    if message == "Field required":
        return f"{field_label} is required."
    if error_type == "string_too_long":
        return f"{field_label} must be at most {context.get('max_length')} characters."
    if error_type == "string_too_short":
        return f"{field_label} is required."
    if error_type == "greater_than":
        return f"{field_label} must be greater than {context.get('gt')}."
    if error_type == "greater_than_equal":
        return f"{field_label} must be {context.get('ge')} or greater."
    if error_type == "less_than_equal":
        return f"{field_label} must be {context.get('le')} or less."
    return message


# -------------------------
# Request models
# -------------------------
class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class StorageSitePayload(StrictModel):
    site_name: str = Field(min_length=1, max_length=100)
    city: str = Field(min_length=1, max_length=80)
    state: str = Field(min_length=2, max_length=2)

    @field_validator("site_name", "city", mode="before")
    @classmethod
    def clean_text(cls, value):
        return strip_required(value)

    @field_validator("state", mode="before")
    @classmethod
    def clean_state(cls, value):
        value = strip_required(value)
        if isinstance(value, str):
            value = value.upper()
        return value

    @field_validator("state")
    @classmethod
    def validate_state(cls, value):
        if not re.fullmatch(r"[A-Z]{2}", value):
            raise ValueError("State must be a two-letter uppercase abbreviation.")
        return value


class SourcePayload(StrictModel):
    source_name: str = Field(min_length=1, max_length=120)
    source_type: SourceType

    @field_validator("source_name", mode="before")
    @classmethod
    def clean_text(cls, value):
        return strip_required(value)


class ProductPayload(StrictModel):
    product_name: str = Field(min_length=1, max_length=120)
    status: Status = "OUT_OF_STOCK"
    product_condition: Condition = "GOOD"
    product_quantity: int = Field(default=0, ge=0)
    cost: Decimal = Field(default=Decimal("0.00"), ge=Decimal("0.00"), le=MONEY_MAX)
    profit: Decimal = Field(default=Decimal("0.00"), ge=PROFIT_MIN, le=MONEY_MAX)
    date_added: date
    date_sold: date | None = None
    site_id: int = Field(default=1, gt=0)

    @field_validator("product_name", mode="before")
    @classmethod
    def clean_text(cls, value):
        return strip_required(value)

    @model_validator(mode="after")
    def validate_product_state(self):
        if self.date_sold and self.date_sold < self.date_added:
            raise ValueError("Date sold cannot be earlier than date added.")

        if self.status in {"IN_STOCK", "RESERVED"}:
            if self.product_quantity <= 0:
                raise ValueError("In-stock and reserved products must have quantity greater than 0.")
            if self.date_sold is not None:
                raise ValueError("In-stock and reserved products cannot have a sold date.")

        if self.status == "OUT_OF_STOCK":
            if self.product_quantity != 0:
                raise ValueError("Out-of-stock products must have quantity 0.")
            if self.date_sold is not None:
                raise ValueError("Out-of-stock products cannot have a sold date.")

        if self.status == "SOLD":
            if self.product_quantity != 0:
                raise ValueError("Sold products must have quantity 0.")
            if self.date_sold is None:
                raise ValueError("Sold products must have a sold date.")

        if self.status == "DISCONTINUED" and self.date_sold is not None:
            raise ValueError("Discontinued products cannot have a sold date.")

        return self


class PurchasePayload(StrictModel):
    purchase_date: date
    purchase_quantity: int = Field(gt=0)
    unit_cost: Decimal = Field(ge=Decimal("0.00"), le=MONEY_MAX)
    product_id: int = Field(gt=0)
    source_id: int = Field(gt=0)


class TransactionPayload(StrictModel):
    transaction_date: date
    transaction_type: TransactionType
    transaction_quantity: int = Field(gt=0)
    unit_price: Decimal = Field(default=Decimal("0.00"), ge=Decimal("0.00"), le=MONEY_MAX)
    product_id: int = Field(gt=0)

    @model_validator(mode="after")
    def validate_sale_price(self):
        if self.transaction_type == "SALE" and self.unit_price <= 0:
            raise ValueError("Sale transactions must have a unit price greater than 0.")
        return self


# -------------------------
# Inventory helpers
# -------------------------
def transaction_effect(transaction):
    qty = int(transaction["transaction_quantity"])
    tx_type = transaction["transaction_type"]
    if tx_type in INBOUND_TYPES:
        return qty
    if tx_type in OUTBOUND_TYPES:
        return -qty
    raise AppError("Invalid transaction type.")


def sale_profit_delta(transaction, product_cost):
    if transaction["transaction_type"] != "SALE":
        return Decimal("0.00")
    return money((decimal_value(transaction["unit_price"]) - decimal_value(product_cost)) * int(transaction["transaction_quantity"]))


def lock_product(cur, product_id):
    cur.execute(
        """
        SELECT product_id, product_quantity, cost, profit, status, date_added, date_sold
        FROM Product
        WHERE product_id=%s
        FOR UPDATE
        """,
        (product_id,),
    )
    product = cur.fetchone()
    if not product:
        raise AppError("The selected product does not exist.", 404)
    return product


def lock_products(cur, product_ids):
    products = {}
    for product_id in sorted(set(product_ids)):
        products[product_id] = lock_product(cur, product_id)
    return products


def validate_transaction_date(product, transaction):
    if transaction["transaction_date"] < product["date_added"]:
        raise AppError("Transaction date cannot be earlier than the product date added.")


def next_product_status(current_status, quantity, sold_date=None):
    if quantity < 0:
        raise AppError("Not enough inventory for this transaction.")
    if quantity > 0:
        if current_status in {"IN_STOCK", "RESERVED", "DISCONTINUED"}:
            return current_status, None
        return "IN_STOCK", None
    if sold_date is not None:
        return "SOLD", sold_date
    return "OUT_OF_STOCK", None


def update_product_inventory(cur, product, quantity, profit, sold_date=None):
    if sold_date is not None and sold_date < product["date_added"]:
        raise AppError("Sold date cannot be earlier than date added.")

    status, final_sold_date = next_product_status(product["status"], quantity, sold_date)
    cur.execute(
        """
        UPDATE Product
        SET product_quantity=%s, profit=%s, status=%s, date_sold=%s
        WHERE product_id=%s
        """,
        (quantity, money(profit), status, final_sold_date, product["product_id"]),
    )


def transaction_dict(payload: TransactionPayload):
    return payload.model_dump()


def lock_transaction(cur, transaction_id):
    cur.execute(
        """
        SELECT transaction_id, transaction_date, transaction_type, transaction_quantity, unit_price, product_id
        FROM Inventory_Transaction
        WHERE transaction_id=%s
        FOR UPDATE
        """,
        (transaction_id,),
    )
    transaction = cur.fetchone()
    if not transaction:
        raise AppError("Transaction not found.", 404)
    return transaction


def create_inventory_transaction(cur, payload: TransactionPayload):
    data = transaction_dict(payload)
    product = lock_product(cur, payload.product_id)
    validate_transaction_date(product, data)

    new_quantity = int(product["product_quantity"]) + transaction_effect(data)
    if new_quantity < 0:
        raise AppError("Not enough inventory for this transaction.")

    new_profit = decimal_value(product["profit"]) + sale_profit_delta(data, product["cost"])

    cur.execute(
        """
        INSERT INTO Inventory_Transaction
            (product_id, transaction_quantity, transaction_type, unit_price, transaction_date)
        VALUES (%s, %s, %s, %s, %s)
        """,
        (
            data["product_id"],
            data["transaction_quantity"],
            data["transaction_type"],
            data["unit_price"],
            data["transaction_date"],
        ),
    )
    transaction_id = cur.lastrowid

    sold_date = data["transaction_date"] if data["transaction_type"] == "SALE" and new_quantity == 0 else None
    update_product_inventory(cur, product, new_quantity, new_profit, sold_date)
    return {"transaction_id": transaction_id}


def update_inventory_transaction(cur, transaction_id: int, payload: TransactionPayload):
    old_transaction = lock_transaction(cur, transaction_id)
    new_transaction = transaction_dict(payload)
    products = lock_products(cur, {old_transaction["product_id"], new_transaction["product_id"]})

    if old_transaction["product_id"] == new_transaction["product_id"]:
        product = products[old_transaction["product_id"]]
        validate_transaction_date(product, new_transaction)

        next_quantity = (
            int(product["product_quantity"])
            - transaction_effect(old_transaction)
            + transaction_effect(new_transaction)
        )
        if next_quantity < 0:
            raise AppError("This edit would make product inventory negative.")

        next_profit = (
            decimal_value(product["profit"])
            - sale_profit_delta(old_transaction, product["cost"])
            + sale_profit_delta(new_transaction, product["cost"])
        )
        sold_date = (
            new_transaction["transaction_date"]
            if new_transaction["transaction_type"] == "SALE" and next_quantity == 0
            else None
        )
        update_product_inventory(cur, product, next_quantity, next_profit, sold_date)
    else:
        old_product = products[old_transaction["product_id"]]
        old_quantity = int(old_product["product_quantity"]) - transaction_effect(old_transaction)
        if old_quantity < 0:
            raise AppError("This edit would make the old product inventory negative.")
        old_profit = decimal_value(old_product["profit"]) - sale_profit_delta(old_transaction, old_product["cost"])
        update_product_inventory(cur, old_product, old_quantity, old_profit)

        new_product = products[new_transaction["product_id"]]
        validate_transaction_date(new_product, new_transaction)

        new_quantity = int(new_product["product_quantity"]) + transaction_effect(new_transaction)
        if new_quantity < 0:
            raise AppError("Not enough inventory for the selected product.")
        new_profit = decimal_value(new_product["profit"]) + sale_profit_delta(new_transaction, new_product["cost"])
        sold_date = (
            new_transaction["transaction_date"]
            if new_transaction["transaction_type"] == "SALE" and new_quantity == 0
            else None
        )
        update_product_inventory(cur, new_product, new_quantity, new_profit, sold_date)

    cur.execute(
        """
        UPDATE Inventory_Transaction
        SET product_id=%s, transaction_quantity=%s, transaction_type=%s, unit_price=%s, transaction_date=%s
        WHERE transaction_id=%s
        """,
        (
            new_transaction["product_id"],
            new_transaction["transaction_quantity"],
            new_transaction["transaction_type"],
            new_transaction["unit_price"],
            new_transaction["transaction_date"],
            transaction_id,
        ),
    )
    return {"updated": cur.rowcount}


def delete_inventory_transaction(cur, transaction_id: int):
    transaction = lock_transaction(cur, transaction_id)
    product = lock_product(cur, transaction["product_id"])

    next_quantity = int(product["product_quantity"]) - transaction_effect(transaction)
    if next_quantity < 0:
        raise AppError("This delete would make product inventory negative.")

    next_profit = decimal_value(product["profit"]) - sale_profit_delta(transaction, product["cost"])
    update_product_inventory(cur, product, next_quantity, next_profit)

    cur.execute("DELETE FROM Inventory_Transaction WHERE transaction_id=%s", (transaction_id,))
    return {"deleted": cur.rowcount}


# -------------------------
# App
# -------------------------
app = FastAPI(docs_url=None, redoc_url=None, openapi_url=None)


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return error_response(first_validation_message(exc), 422)


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
    except mysql.connector.Error:
        return error_response("Database unavailable. Confirm MySQL is running and db_config.json is correct.", 503)
    finally:
        close_db(cur, conn)


# -------------------------
# STORAGE SITES
# -------------------------
@app.get("/api/storage-sites")
def get_sites():
    return fetch_all("SELECT site_id, site_name, city, state FROM Storage_Site")


@app.post("/api/storage-sites")
def create_site(body: StorageSitePayload):
    def work(cur):
        data = body.model_dump()
        cur.execute(
            "INSERT INTO Storage_Site (site_name, city, state) VALUES (%s, %s, %s)",
            (data["site_name"], data["city"], data["state"]),
        )
        return {"site_id": cur.lastrowid}

    return db_write(work)


@app.put("/api/storage-sites/{site_id}")
def update_site(site_id: int, body: StorageSitePayload):
    def work(cur):
        data = body.model_dump()
        cur.execute(
            "UPDATE Storage_Site SET site_name=%s, city=%s, state=%s WHERE site_id=%s",
            (data["site_name"], data["city"], data["state"], site_id),
        )
        return {"updated": cur.rowcount}

    return db_write(work)


@app.delete("/api/storage-sites/{site_id}")
def delete_site(site_id: int):
    return db_write(lambda cur: _delete_row(cur, "Storage_Site", "site_id", site_id))


# -------------------------
# SOURCES
# -------------------------
@app.get("/api/sources")
def get_sources():
    return fetch_all("SELECT source_id, source_name, source_type FROM Source_or_Supplier")


@app.post("/api/sources")
def create_source(body: SourcePayload):
    def work(cur):
        data = body.model_dump()
        cur.execute(
            "INSERT INTO Source_or_Supplier (source_name, source_type) VALUES (%s, %s)",
            (data["source_name"], data["source_type"]),
        )
        return {"source_id": cur.lastrowid}

    return db_write(work)


@app.put("/api/sources/{source_id}")
def update_source(source_id: int, body: SourcePayload):
    def work(cur):
        data = body.model_dump()
        cur.execute(
            "UPDATE Source_or_Supplier SET source_name=%s, source_type=%s WHERE source_id=%s",
            (data["source_name"], data["source_type"], source_id),
        )
        return {"updated": cur.rowcount}

    return db_write(work)


@app.delete("/api/sources/{source_id}")
def delete_source(source_id: int):
    return db_write(lambda cur: _delete_row(cur, "Source_or_Supplier", "source_id", source_id))


# -------------------------
# PRODUCTS
# -------------------------
@app.get("/api/products")
def get_products():
    return fetch_all(
        """
        SELECT
            product_id, product_name, status, product_condition,
            product_quantity, cost, profit, date_added, date_sold, site_id
        FROM Product
        """
    )


@app.post("/api/products")
def create_product(body: ProductPayload):
    def work(cur):
        data = body.model_dump()
        cur.execute(
            """
            INSERT INTO Product
                (product_name, status, product_condition, product_quantity, cost, profit, date_added, date_sold, site_id)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (
                data["product_name"],
                data["status"],
                data["product_condition"],
                data["product_quantity"],
                money(data["cost"]),
                money(data["profit"]),
                data["date_added"],
                data["date_sold"],
                data["site_id"],
            ),
        )
        return {"product_id": cur.lastrowid}

    return db_write(work)


@app.put("/api/products/{product_id}")
def update_product(product_id: int, body: ProductPayload):
    def work(cur):
        data = body.model_dump()
        cur.execute(
            """
            UPDATE Product
            SET product_name=%s, status=%s, product_condition=%s, product_quantity=%s,
                cost=%s, profit=%s, date_added=%s, date_sold=%s, site_id=%s
            WHERE product_id=%s
            """,
            (
                data["product_name"],
                data["status"],
                data["product_condition"],
                data["product_quantity"],
                money(data["cost"]),
                money(data["profit"]),
                data["date_added"],
                data["date_sold"],
                data["site_id"],
                product_id,
            ),
        )
        return {"updated": cur.rowcount}

    return db_write(work)


@app.delete("/api/products/{product_id}")
def delete_product(product_id: int):
    return db_write(lambda cur: _delete_row(cur, "Product", "product_id", product_id))

# -------------------------
# PURCHASE RECORDS
# -------------------------
@app.get("/api/purchases")
def get_purchases():
    return fetch_all(
        """
        SELECT purchase_id, purchase_date, purchase_quantity, unit_cost, total_cost, product_id, source_id
        FROM Purchase_or_Order
        """
    )


@app.post("/api/purchases")
def create_purchase(body: PurchasePayload):
    def work(cur):
        data = body.model_dump()
        cur.execute(
            """
            INSERT INTO Purchase_or_Order
                (purchase_date, purchase_quantity, unit_cost, product_id, source_id)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (
                data["purchase_date"],
                data["purchase_quantity"],
                money(data["unit_cost"]),
                data["product_id"],
                data["source_id"],
            ),
        )
        return {"purchase_id": cur.lastrowid}

    return db_write(work)


@app.put("/api/purchases/{purchase_id}")
def update_purchase(purchase_id: int, body: PurchasePayload):
    def work(cur):
        data = body.model_dump()
        cur.execute(
            """
            UPDATE Purchase_or_Order
            SET purchase_date=%s, purchase_quantity=%s, unit_cost=%s, product_id=%s, source_id=%s
            WHERE purchase_id=%s
            """,
            (
                data["purchase_date"],
                data["purchase_quantity"],
                money(data["unit_cost"]),
                data["product_id"],
                data["source_id"],
                purchase_id,
            ),
        )
        return {"updated": cur.rowcount}

    return db_write(work)


@app.delete("/api/purchases/{purchase_id}")
def delete_purchase(purchase_id: int):
    return db_write(lambda cur: _delete_row(cur, "Purchase_or_Order", "purchase_id", purchase_id))


# -------------------------
# TRANSACTIONS
# -------------------------
@app.get("/api/transactions")
def get_transactions():
    return fetch_all(
        """
        SELECT
            transaction_id, transaction_date, transaction_type,
            transaction_quantity, unit_price, total_amount, product_id
        FROM Inventory_Transaction
        """
    )


@app.post("/api/transactions")
def create_transaction(body: TransactionPayload):
    return db_write(lambda cur: create_inventory_transaction(cur, body))


@app.put("/api/transactions/{transaction_id}")
def update_transaction(transaction_id: int, body: TransactionPayload):
    return db_write(lambda cur: update_inventory_transaction(cur, transaction_id, body))


@app.delete("/api/transactions/{transaction_id}")
def delete_transaction(transaction_id: int):
    return db_write(lambda cur: delete_inventory_transaction(cur, transaction_id))


def _delete_row(cur, table_name, id_column, row_id):
    cur.execute(f"DELETE FROM {table_name} WHERE {id_column}=%s", (row_id,))
    return {"deleted": cur.rowcount}

# -------------------------
# REPORTS
# -------------------------
@app.get("/api/reports/inventory-by-site")
def report_inventory_by_site():
    return fetch_all(
        """
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
        """
    )


@app.get("/api/reports/site-summary")
def report_site_summary():
    return fetch_all(
        """
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
        """
    )


@app.get("/api/reports/status-summary")
def report_status_summary():
    return fetch_all(
        """
        SELECT
            status,
            COUNT(*)                                        AS product_count,
            SUM(product_quantity)                           AS units_remaining
        FROM Product
        GROUP BY status
        ORDER BY product_count DESC
        """
    )


@app.get("/api/reports/aging")
def report_aging():
    return fetch_all(
        """
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
        """
    )


@app.get("/api/reports/supplier-history")
def report_supplier_history():
    return fetch_all(
        """
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
        """
    )


@app.get("/api/reports/transaction-history")
def report_transaction_history():
    return fetch_all(
        """
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
        """
    )


@app.get("/api/reports/sales-profit")
def report_sales_profit():
    return fetch_all(
        """
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
        """
    )


@app.get("/api/reports/profit-summary")
def report_profit_summary():
    return fetch_all(
        """
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
        """
    )


@app.get("/api/reports/financial-summary")
def report_financial_summary():
    return fetch_all(
        """
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
        """
    )


@app.get("/api/reports/dead-stock")
def report_dead_stock():
    return fetch_all(
        """
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
        """
    )


# -------------------------
# Serve frontend
# -------------------------
app.mount("/", StaticFiles(directory=str(FRONTEND_DIR), html=True), name="frontend")
