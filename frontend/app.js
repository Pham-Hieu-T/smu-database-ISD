(() => {
// Main frontend file.
// This code changes pages, calls the backend, and draws tables/forms.

// All backend routes start with /api.

const API = "/api";
const schema = window.inventorySchema;

// Main HTML elements used by the app.
const app = document.querySelector("#app");
const pageTitle = document.querySelector("#page-title");
const healthPill = document.querySelector("#health-pill");

if (!schema) {
  app.innerHTML = `
    <div class="error-box">
      <strong>Page setup error</strong>
      <p>The table schema did not load. Refresh the page once.</p>
    </div>
  `;
  throw new Error("schema.js did not load before app.js");
}

// These come from schema.js.
const { reports, tables } = schema;

// Small amount of page state.
let currentRoute = getRoute();
let currentRows = [];
let currentReportId = "inventory-by-site";

document.querySelectorAll("[data-route]").forEach((button) => {
  button.addEventListener("click", () => {
    window.location.hash = button.dataset.route;
  });
});

// Refresh redraws the current page.
document.querySelector("#refresh-view").addEventListener("click", showCurrentPage);

// When the hash changes, show the matching page.
window.addEventListener("hashchange", () => {
  currentRoute = getRoute();
  showCurrentPage();
});

// Escape closes any open form.
window.addEventListener("keydown", (event) => {
  if (event.key === "Escape") closeModal();
});

// Start the app.
showCurrentPage();
checkBackend();

// Read the page name from the URL hash.
function getRoute() {
  return window.location.hash.replace("#", "") || "dashboard";
}

// Update the title and selected nav button.
function setPageTitle(title) {
  pageTitle.textContent = title;
  document.querySelectorAll("[data-route]").forEach((button) => {
    button.classList.toggle("is-active", button.dataset.route === currentRoute);
  });
}

// Decide which page to show.
function showCurrentPage() {
  closeModal();

  if (currentRoute === "dashboard") {
    setPageTitle("Dashboard");
    showDashboard();
    return;
  }

  if (currentRoute === "reports") {
    setPageTitle("Reports");
    showReports();
    return;
  }

  if (tables[currentRoute]) {
    setPageTitle(tables[currentRoute].title);
    showTablePage(tables[currentRoute]);
    return;
  }

  window.location.hash = "dashboard";
}

// Check if the backend is running.
async function checkBackend() {
  healthPill.textContent = "Checking";
  healthPill.className = "status-pill is-checking";

  try {
    await apiGet("/health");
    healthPill.textContent = "Connected";
    healthPill.className = "status-pill is-ok";
  } catch {
    healthPill.textContent = "Offline";
    healthPill.className = "status-pill is-error";
  }
}

// Dashboard shows a few totals and the site summary report.
async function showDashboard() {
  app.innerHTML = `<p class="loading">Loading dashboard...</p>`;

  try {
    const products = await apiGet("/products");
    const siteSummary = await apiGet("/reports/site-summary");
    const financial = (await apiGet("/reports/financial-summary"))[0] || {};

    const totalUnits = products.reduce((total, row) => total + Number(row.product_quantity || 0), 0);
    const inventoryValue = financial.live_inventory_value || 0;
    const totalProfit = financial.total_realized_profit || 0;

    app.innerHTML = `
      <section class="summary-grid">
        ${summaryBox("Products", products.length)}
        ${summaryBox("Units", totalUnits)}
        ${summaryBox("Inventory Value", money(inventoryValue))}
        ${summaryBox("Realized Profit", money(totalProfit))}
      </section>

      <section class="panel">
        <div class="panel-header">
          <h2>Site Summary</h2>
        </div>
        ${makeTable(siteSummary, ["storage_unit", "product_types", "total_units", "total_inventory_value"])}
      </section>
    `;
  } catch (error) {
    showError(error);
  }
}

// Small stat box used on the dashboard.
function summaryBox(label, value) {
  return `
    <div class="summary-box">
      <span>${escapeHtml(label)}</span>
      <strong>${escapeHtml(value)}</strong>
    </div>
  `;
}

// Show one CRUD table page, like Products or Transactions.
async function showTablePage(table) {
  app.innerHTML = `
    <section class="panel">
      <div class="panel-header">
        <h2>${table.title}</h2>
        <div class="toolbar">
          <input id="search-input" type="search" placeholder="${table.searchLabel}">
          ${filterHtml(table)}
          <button class="plain-button" id="new-row" type="button">New ${table.singular}</button>
        </div>
      </div>
      <div id="table-output">
        <p class="loading">Loading ${table.title.toLowerCase()}...</p>
      </div>
    </section>
  `;

  document.querySelector("#search-input").addEventListener("input", () => drawTableRows(table));
  document.querySelector("#new-row").addEventListener("click", () => openForm(table));

  const filter = document.querySelector("#filter-input");
  if (filter) filter.addEventListener("change", () => drawTableRows(table));

  try {
    currentRows = await apiGet(table.path);
    drawTableRows(table);
  } catch (error) {
    document.querySelector("#table-output").innerHTML = errorHtml(error);
  }
}

// Build the optional dropdown filter for a table.
function filterHtml(table) {
  if (!table.filter) return "";

  return `
    <select id="filter-input" aria-label="Filter">
      <option value="">All ${escapeHtml(label(table.filter.key))}</option>
      ${table.filter.options.map((option) => `<option value="${escapeAttr(option)}">${escapeHtml(label(option))}</option>`).join("")}
    </select>
  `;
}

// Search/filter rows and redraw the table.
function drawTableRows(table) {
  const searchText = document.querySelector("#search-input").value.toLowerCase();
  const filterValue = document.querySelector("#filter-input")?.value || "";

  const rows = currentRows.filter((row) => {
    const matchesSearch = Object.values(row).join(" ").toLowerCase().includes(searchText);
    const matchesFilter = !table.filter || !filterValue || row[table.filter.key] === filterValue;
    return matchesSearch && matchesFilter;
  });

  document.querySelector("#table-output").innerHTML = makeTable(rows, table.columns, true);

  document.querySelectorAll("[data-edit]").forEach((button) => {
    button.addEventListener("click", () => openForm(table, rows[Number(button.dataset.edit)]));
  });

  document.querySelectorAll("[data-delete]").forEach((button) => {
    button.addEventListener("click", () => deleteRow(table, rows[Number(button.dataset.delete)]));
  });
}

// Show the report page and load the selected report.
async function showReports() {
  const report = reports.find(([id]) => id === currentReportId) || reports[0];

  app.innerHTML = `
    <section class="panel">
      <div class="panel-header">
        <h2>${report[1]}</h2>
      </div>
      <div class="report-tabs">
        ${reports
          .map(([id, name]) => `<button class="report-tab ${id === report[0] ? "is-active" : ""}" data-report="${id}" type="button">${name}</button>`)
          .join("")}
      </div>
      <div id="report-output">
        <p class="loading">Loading report...</p>
      </div>
    </section>
  `;

  document.querySelectorAll("[data-report]").forEach((button) => {
    button.addEventListener("click", () => {
      currentReportId = button.dataset.report;
      showReports();
    });
  });

  try {
    const rows = await apiGet(`/reports/${report[0]}`);
    document.querySelector("#report-output").innerHTML = makeTable(rows, columnsFromRows(rows));
  } catch (error) {
    document.querySelector("#report-output").innerHTML = errorHtml(error);
  }
}

// Build an HTML table from rows returned by the backend.
function makeTable(rows, columns, showActions = false) {
  if (!rows.length) {
    return `<p class="empty">No rows returned.</p>`;
  }

  return `
    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            ${columns.map((column) => `<th>${escapeHtml(label(column))}</th>`).join("")}
            ${showActions ? "<th>Actions</th>" : ""}
          </tr>
        </thead>
        <tbody>
          ${rows
            .map(
              (row, index) => `
                <tr>
                  ${columns.map((column) => `<td>${formatValue(column, row[column])}</td>`).join("")}
                  ${
                    showActions
                      ? `<td class="actions"><button data-edit="${index}" type="button">Edit</button> <button data-delete="${index}" type="button">Delete</button></td>`
                      : ""
                  }
                </tr>
              `,
            )
            .join("")}
        </tbody>
      </table>
    </div>
  `;
}

// Open the add/edit form modal.
function openForm(table, row = null) {
  const isEdit = Boolean(row);

  document.querySelector("#modal-root").innerHTML = `
    <div class="modal-backdrop">
      <form class="modal" id="row-form">
        <div class="modal-header">
          <h2>${isEdit ? "Edit" : "New"} ${table.singular}</h2>
          <button class="plain-button" id="close-modal" type="button">Close</button>
        </div>
        <div class="form-grid">
          ${table.fields.map((field) => fieldHtml(field, row?.[field.key])).join("")}
        </div>
        <p class="form-error" id="form-error"></p>
        <div class="modal-actions">
          <button class="plain-button" type="button" id="cancel-modal">Cancel</button>
          <button class="primary-button" type="submit">Save</button>
        </div>
      </form>
    </div>
  `;

  document.querySelector("#close-modal").addEventListener("click", closeModal);
  document.querySelector("#cancel-modal").addEventListener("click", closeModal);
  document.querySelector("#row-form").addEventListener("submit", (event) => saveRow(event, table, row));
}

// Make one form field from the schema.
function fieldHtml(field, value = "") {
  const required = field.required ? "required" : "";
  const safeValue = value == null ? "" : escapeAttr(value);

  if (field.type === "select") {
    return `
      <label>
        ${escapeHtml(field.label)}
        <select name="${field.key}" ${required}>
          <option value=""></option>
          ${field.options.map((option) => `<option value="${escapeAttr(option)}" ${option === value ? "selected" : ""}>${escapeHtml(label(option))}</option>`).join("")}
        </select>
      </label>
    `;
  }

  return `
    <label>
      ${escapeHtml(field.label)}
      <input
        name="${field.key}"
        type="${field.type}"
        value="${safeValue}"
        ${required}
        ${field.min != null ? `min="${field.min}"` : ""}
        ${field.step != null ? `step="${field.step}"` : ""}
        ${field.maxLength != null ? `maxlength="${field.maxLength}"` : ""}
      >
    </label>
  `;
}

// Send form data to the backend.
async function saveRow(event, table, oldRow) {
  event.preventDefault();

  const form = event.currentTarget;
  const data = {};

  table.fields.forEach((field) => {
    const rawValue = form.elements[field.key].value.trim();
    let value = field.uppercase ? rawValue.toUpperCase() : rawValue;

    if (field.type === "number") value = value === "" ? null : Number(value);
    if (field.type !== "number") value = value === "" ? null : value;

    data[field.key] = value;
  });

  const id = oldRow?.[table.id];
  const path = id == null ? table.path : `${table.path}/${encodeURIComponent(id)}`;
  const method = id == null ? "POST" : "PUT";

  try {
    await apiSend(path, method, data);
    closeModal();
    showTablePage(table);
  } catch (error) {
    document.querySelector("#form-error").textContent = error.message;
  }
}

// Delete a row through the backend.
async function deleteRow(table, row) {
  const id = row?.[table.id];
  if (id == null) return;

  if (!window.confirm(`Delete ${table.singular.toLowerCase()} #${id}?`)) return;

  try {
    await apiSend(`${table.path}/${encodeURIComponent(id)}`, "DELETE");
    showTablePage(table);
  } catch (error) {
    window.alert(error.message);
  }
}

// Close the form modal.
function closeModal() {
  document.querySelector("#modal-root").innerHTML = "";
}

// GET helper.
async function apiGet(path) {
  return apiSend(path, "GET");
}

// Main API helper used for GET, POST, PUT, and DELETE.
async function apiSend(path, method, data = null) {
  const controller = new AbortController();
  const timeout = window.setTimeout(() => controller.abort(), 4000);
  const options = { method, headers: { Accept: "application/json" } };

  if (data) {
    options.headers["Content-Type"] = "application/json";
    options.body = JSON.stringify(data);
  }

  let response;
  try {
    response = await fetch(API + path, { ...options, signal: controller.signal });
  } catch {
    throw new Error("Cannot reach the local backend. Make sure the backend server is running.");
  } finally {
    window.clearTimeout(timeout);
  }

  // The backend should always send JSON.
  let body = {};
  try {
    const text = await response.text();
    body = text ? JSON.parse(text) : {};
  } catch {
    throw new Error("Backend route is missing or did not return JSON.");
  }

  if (!response.ok) {
    throw new Error(body.error?.message || "Request failed.");
  }

  const result = body.data || [];
  return Array.isArray(result) ? result : [result];
}

// Reports can return different columns, so this finds them automatically.
function columnsFromRows(rows) {
  const columns = [];
  rows.forEach((row) => {
    Object.keys(row).forEach((key) => {
      if (!columns.includes(key)) columns.push(key);
    });
  });
  return columns;
}

// Show a full-page error.
function showError(error) {
  app.innerHTML = errorHtml(error);
}

// Error HTML used when the backend is missing or returns a bad response.
function errorHtml(error) {
  return `
    <div class="error-box">
      <strong>Backend unavailable</strong>
      <p>${escapeHtml(error.message)}</p>
    </div>
  `;
}

// Format one table cell.
function formatValue(key, value) {
  if (value == null || value === "") return "";
  if (moneyFields(key)) return money(value);
  if (["status", "product_condition", "source_type", "transaction_type", "stock_health"].includes(key)) {
    return `<span class="badge">${label(value)}</span>`;
  }
  return escapeHtml(value);
}

// Decide which columns should be formatted as money.
function moneyFields(key) {
  if (key === "profit_margin") return false;
  return /cost|price|amount|profit|value|capital|revenue|spent/i.test(key);
}

// Format a number as dollars.
function money(value) {
  return Number(value || 0).toLocaleString("en-US", {
    style: "currency",
    currency: "USD",
  });
}

// Turn snake_case or ENUM values into normal words.
function label(value) {
  return String(value)
    .replaceAll("_", " ")
    .replace(/\b\w/g, (letter) => letter.toUpperCase());
}

// Basic HTML escaping so database text does not become HTML.
function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

// Escape text before putting it inside an input value.
function escapeAttr(value) {
  return escapeHtml(value).replaceAll("`", "&#096;");
}
})();
