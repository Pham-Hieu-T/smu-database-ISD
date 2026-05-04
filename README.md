# Inventory Storage Database App

This project is a local MySQL/MariaDB-backed inventory and storage application with a browser GUI.

## Demo Run

From the repo root:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
mysql -u root -p < sql/01_create_database.sql
mysql -u root -p < sql/02_create_tables.sql
mysql -u root -p < sql/03_seed_data.sql
python run_app.py
```

Open:

```text
http://127.0.0.1:8000
```

## Database Config

The app reads database connection settings from:

```text
backend/db_config.json
```

Update that file to match your local MySQL/MariaDB username, password, host, port, and database name.

## Project Notes

- The user should use the browser GUI, not a MySQL GUI.
- The browser does not contain database credentials.
- The backend serves both the static frontend and `/api` routes.
- API docs are disabled for the final demo.
- Detailed backend instructions are in `backend/readme.md`.
- Database setup/query notes are in `sql/README_database.md`.
