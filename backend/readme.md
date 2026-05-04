# Backend / Full App Run Instructions

This project runs as one local FastAPI app:

- The browser GUI is served from `frontend/`.
- The database API is served under `/api`.
- MySQL/MariaDB settings are read from `backend/db_config.json`.

## 1. Install Python packages

From the repo root:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## 2. Set up MySQL or MariaDB

Start your local MySQL/MariaDB server, then run the SQL files from the repo root:

```bash
mysql -u root -p < sql/01_create_database.sql
mysql -u root -p < sql/02_create_tables.sql
mysql -u root -p < sql/03_seed_data.sql
```

Optional checks:

```bash
mysql -u root -p < sql/04_test_queries.sql
mysql -u root -p < sql/05_queries.sql
```

## 3. Configure database login

Edit `backend/db_config.json` so it matches your local database:

```json
{
  "host": "localhost",
  "port": 3306,
  "user": "root",
  "password": "",
  "database": "inventory_storage_db"
}
```

## 4. Run the app

From the repo root, with the virtual environment active:

```bash
python run_app.py
```

Open:

```text
http://127.0.0.1:8000
```

The frontend should show `Backend Connected` when the app can reach MySQL.

## Notes for Demo

- Do not run a separate frontend server for the final demo.
- Do not enter the database directly during the demo.
- Use the browser GUI at `http://127.0.0.1:8000`.
- If the frontend says the backend is offline, confirm MySQL is running and `backend/db_config.json` is correct.
