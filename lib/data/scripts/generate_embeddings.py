import sqlite3
import json
import os
import sys
from sentence_transformers import SentenceTransformer
from tqdm import tqdm

# Configuration
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# Go up 3 levels from lib/data/scripts to project root
PROJECT_ROOT = os.path.abspath(os.path.join(BASE_DIR, '../../../'))
DB_PATH = os.path.join(PROJECT_ROOT, 'assets/database/geeta_v2.db')
MODEL_NAME = 'sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2'

def main():
    # 1. Setup & DB Connection
    target_db = DB_PATH
    if not os.path.exists(target_db):
        print(f"Error: Database not found at '{DB_PATH}'")
        sys.exit(1)
            
    print(f"Using database: {target_db}")
    
    print(f"Loading model: {MODEL_NAME}...")
    # Load the model
    model = SentenceTransformer(MODEL_NAME)
    print("Model loaded successfully.")

    try:
        conn = sqlite3.connect(target_db)
        cursor = conn.cursor()

        # 2. Prepare Table
        print("Checking table schema...")
        cursor.execute("PRAGMA table_info(translations)")
        columns = [col[1] for col in cursor.fetchall()]

        if 'embedding' not in columns:
            print("Adding 'embedding' column to 'translations' table...")
            cursor.execute("ALTER TABLE translations ADD COLUMN embedding TEXT")
            conn.commit()
        else:
            print("'embedding' column already exists.")

        # 3. Fetch Data with JOIN
        print("Fetching records to process...")
        # Select rowid, language, bhavarth, and speaker
        query = """
            SELECT t.rowid, t.bhavarth, t.language_code, m.speaker
            FROM translations t
            JOIN master_shlokas m ON t.shloka_id = m.id
            WHERE t.language_code IN ('en', 'hi')
            AND t.bhavarth IS NOT NULL 
            AND t.bhavarth != ''
        """
        cursor.execute(query)
        rows = cursor.fetchall()
        total_rows = len(rows)
        
        print(f"Found {total_rows} records. Starting embedding generation...")

        # 4. Generate Contextual Embeddings
        # using tqdm for progress bar
        for row in tqdm(rows, desc="Processing shlokas", unit="row"):
            row_id, bhavarth, language_code, speaker = row
            
            # Construct Context String
            # Format: "{speaker} says: {bhavarth}"
            context_text = f"{speaker} says: {bhavarth}"
            
            # Generate vector embedding
            embedding_vector = model.encode(context_text).tolist()
            embedding_json = json.dumps(embedding_vector)

            # Update the specific row in translations using rowid
            update_query = "UPDATE translations SET embedding = ? WHERE rowid = ?"
            cursor.execute(update_query, (embedding_json, row_id))

        conn.commit()
        print(f"\nSuccess! Updated {total_rows} records with contextual embeddings.")

    except sqlite3.Error as e:
        print(f"\nSQLite error: {e}")
    except Exception as e:
        print(f"\nAn error occurred: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main()
