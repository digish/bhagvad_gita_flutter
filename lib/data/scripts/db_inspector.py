import sqlite3
import json
import sys
import os

# CONFIGURATION: Change this to your database filename
DB_PATH = '../../../assets/database/geeta_v2.db' 

def inspect_database(db_path):
    if not os.path.exists(db_path):
        print(f"❌ Error: Database file '{db_path}' not found.")
        print("Please edit the DB_PATH variable in the script to point to your .db file.")
        return

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row # Allows accessing columns by name
    cursor = conn.cursor()

    print(f"--- DATABASE SCHEMA REPORT FOR: {db_path} ---")
    print("Copy everything below this line and paste it to your AI assistant.\n")
    print("```sql")

    # 1. Get all table names
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = cursor.fetchall()

    for table in tables:
        table_name = table['name']
        
        # Skip internal SQLite tables
        if table_name.startswith('sqlite_'):
            continue

        print(f"-- TABLE: {table_name}")
        
        # 2. Get the CREATE statement (Best way for AI to understand schema)
        cursor.execute(f"SELECT sql FROM sqlite_master WHERE type='table' AND name='{table_name}';")
        create_stmt = cursor.fetchone()
        if create_stmt:
            print(create_stmt['sql'].strip() + ";")
        
        # 3. Get one sample row to understand the content format
        try:
            cursor.execute(f"SELECT * FROM {table_name} LIMIT 1")
            sample_row = cursor.fetchone()
            
            print(f"\n/* SAMPLE DATA FOR {table_name}: */")
            if sample_row:
                # Convert row to dictionary for readable JSON output
                row_dict = dict(sample_row)
                # Truncate long text fields to avoid spamming
                for key, value in row_dict.items():
                    if isinstance(value, str) and len(value) > 100:
                        row_dict[key] = value[:100] + "... (truncated)"
                print(json.dumps(row_dict, indent=2))
            else:
                print("-- Table is empty.")
        except Exception as e:
            print(f"-- Error fetching sample data: {e}")

        print("\n" + "="*40 + "\n")

    print("```")
    print("\n--- END REPORT ---")
    conn.close()

if __name__ == "__main__":
    # You can pass the db path as a command line argument, or use the default
    target_db = sys.argv[1] if len(sys.argv) > 1 else DB_PATH
    inspect_database(target_db)