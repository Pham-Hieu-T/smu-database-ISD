(() => {
// This file describes the database tables for the frontend.
// app.js reads this file so it knows which columns and form fields to show.

// These arrays match the ENUM values in the SQL schema.
const STATUS_OPTIONS = ["IN_STOCK", "OUT_OF_STOCK", "RESERVED", "SOLD", "DISCONTINUED"];
const CONDITION_OPTIONS = ["NEW", "GOOD", "FAIR", "POOR", "DAMAGED"];
const SOURCE_OPTIONS = ["SUPPLIER", "DONOR", "AUCTION", "CUSTOMER_RETURN", "OTHER"];
const TRANSACTION_OPTIONS = [
  "PURCHASE",
  "SALE",
  "TRANSFER_IN",
  "TRANSFER_OUT",
  "ADJUSTMENT_IN",
  "ADJUSTMENT_OUT",
  "RETURN",
];

function input(key, label, type, required = false, min = null, step = null, maxLength = null, uppercase = false) {
  return { key, label, type, required, min, step, maxLength, uppercase };
}

// Helper for dropdown fields.
function select(key, label, options) {
  return { key, label, type: "select", required: true, options };
}

// Helper for dropdowns that come from another backend table.
function lookup(key, label, path, idKey, nameKeys) {
  return { key, label, type: "lookup", required: true, path, idKey, nameKeys };
}

// One object per table page in the frontend.
// path is the backend API route.
// columns are shown in the table.
// fields are shown in the add/edit form.
const tables = {
  products: {
    title: "Products",
    singular: "Product",
    path: "/products",
    id: "product_id",
    searchLabel: "Search products",
    filter: { key: "status", options: STATUS_OPTIONS },
    columns: [
      "product_id",
      "product_name",
      "status",
      "product_condition",
      "product_quantity",
      "cost",
      "profit",
      "date_added",
      "date_sold",
      "site_id",
    ],
    fields: [
      input("product_name", "Product name", "text", true),
      select("status", "Status", STATUS_OPTIONS),
      input("cost", "Cost", "number", true, "0", "0.01"),
      input("profit", "Profit", "number", true, null, "0.01"),
      select("product_condition", "Condition", CONDITION_OPTIONS),
      input("date_added", "Date added", "date", true),
      input("date_sold", "Date sold", "date"),
      input("product_quantity", "Quantity", "number", true, "0", "1"),
      lookup("site_id", "Storage site", "/storage-sites", "site_id", ["site_name", "city", "state"]),
    ],
  },
  "storage-sites": {
    title: "Storage Sites",
    singular: "Storage Site",
    path: "/storage-sites",
    id: "site_id",
    searchLabel: "Search storage sites",
    columns: ["site_id", "site_name", "city", "state"],
    fields: [
      input("site_name", "Site name", "text", true),
      input("city", "City", "text", true),
      input("state", "State", "text", true, null, null, 2, true),
    ],
  },
  sources: {
    title: "Sources",
    singular: "Source",
    path: "/sources",
    id: "source_id",
    searchLabel: "Search sources",
    filter: { key: "source_type", options: SOURCE_OPTIONS },
    columns: ["source_id", "source_name", "source_type"],
    fields: [
      input("source_name", "Source name", "text", true),
      select("source_type", "Source type", SOURCE_OPTIONS),
    ],
  },
  purchases: {
    title: "Purchase Records",
    singular: "Purchase Record",
    path: "/purchases",
    id: "purchase_id",
    searchLabel: "Search purchase records",
    columns: ["purchase_id", "purchase_date", "purchase_quantity", "unit_cost", "total_cost", "product_id", "source_id"],
    fields: [
      input("purchase_date", "Purchase date", "date", true),
      input("purchase_quantity", "Quantity", "number", true, "1", "1"),
      input("unit_cost", "Unit cost", "number", true, "0", "0.01"),
      lookup("product_id", "Product", "/products", "product_id", ["product_name", "status"]),
      lookup("source_id", "Source", "/sources", "source_id", ["source_name", "source_type"]),
    ],
  },
  transactions: {
    title: "Transactions",
    singular: "Transaction",
    path: "/transactions",
    id: "transaction_id",
    searchLabel: "Search transactions",
    filter: { key: "transaction_type", options: TRANSACTION_OPTIONS },
    columns: [
      "transaction_id",
      "transaction_date",
      "transaction_type",
      "transaction_quantity",
      "unit_price",
      "total_amount",
      "product_id",
    ],
    fields: [
      input("transaction_date", "Transaction date", "date", true),
      select("transaction_type", "Transaction type", TRANSACTION_OPTIONS),
      input("transaction_quantity", "Quantity", "number", true, "1", "1"),
      input("unit_price", "Unit price", "number", true, "0", "0.01"),
      lookup("product_id", "Product", "/products", "product_id", ["product_name", "status"]),
    ],
  },
};

const reports = [
  ["inventory-by-site", "Inventory by Site"],
  ["site-summary", "Site Summary"],
  ["status-summary", "Status Summary"],
  ["aging", "Aging"],
  ["supplier-history", "Supplier History"],
  ["transaction-history", "Transaction History"],
  ["sales-profit", "Sales Profit"],
  ["profit-summary", "Profit Summary"],
  ["financial-summary", "Financial Summary"],
  ["dead-stock", "Dead Stock"],
];

// Put the schema on window so app.js can read it after this file loads.
window.inventorySchema = { reports, tables };
})();
