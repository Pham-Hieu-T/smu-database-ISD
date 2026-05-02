# 4-Person Work Division

## Summary
Use the inventory/storage ER diagram project. Jameson and Eyo split the database work. William owns backend/app integration. The final report is a shared group deliverable.

## Work Split
- **Andrew: Frontend / GUI**
  - Build the browser UI for storage sites, products, suppliers, purchases/orders, transactions, and reports.
  - Create forms, tables, search/filter screens, and demo-friendly navigation.
  - Integrate with backend endpoints once William provides them.

- **Jameson: Core Database Design**
  - Build the MySQL/MariaDB schema from the ER diagram.
  - Define primary keys, foreign keys, data types, required fields, and relationship rules.
  - Handle table naming issues, especially avoiding reserved names like `Transaction`.
  - Prepare schema setup SQL and sample seed data.

- **Eyo: Database Logic / Queries**
  - Build the harder query/report SQL: inventory by site, product status, supplier purchase history, product transaction history, cost/profit summaries.
  - Validate database behavior with sample data.
  - Help Jameson verify constraints, joins, and edge cases.

- **William: DB HELP / Backend / Integration**
  - Assist Jameson with backend for good coordination / understanding.
  - Build the backend connection to MySQL using a config file for username/password/database name.
  - Implement CRUD routes/services for all major tables.
  - Connect Andrew’s frontend to the database-backed backend.
  - Lead app-level testing and demo readiness.

## Group Report Duties
- **Andrew:** frontend screenshots, user workflow, GUI instructions.
- **Jameson:** schema explanation and table descriptions.
- **Eyo:** query/report explanation and sample outputs.
- **William:** installation guide, backend setup, final packaging.
- Everyone reviews the final report together before submission.

## Test Plan
- Fresh database setup works from SQL scripts.
- All frontend forms can create and retrieve records.
- Foreign keys work correctly across products, sites, suppliers, purchases, and transactions.
- Report/query screens return correct results from seed data.
- Full demo rehearsal confirms every member can explain their section.

## Assumption:
- The report is graded as a group artifact, so everyone contributes.
