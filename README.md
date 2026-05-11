## Run

From the repo root:

```bash
# Create and activate a virtual environment, install dependencies, and set up the database:
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
mysql -u root -p < sql/01_create_database.sql
mysql -u root -p < sql/02_create_tables.sql
mysql -u root -p < sql/03_seed_data.sql

# Run the app:

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
