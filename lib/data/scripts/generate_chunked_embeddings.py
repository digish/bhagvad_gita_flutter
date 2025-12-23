import sqlite3
import json
import os
import sys
from sentence_transformers import SentenceTransformer
from tqdm import tqdm

# Configuration
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(BASE_DIR, '../../../'))
DB_PATH = os.path.join(PROJECT_ROOT, 'assets/database/geeta_v3.db')
MODEL_NAME = 'sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2'

def chunk_text(text, chunk_size=100, overlap=20):
    """Splits text into chunks of approx `chunk_size` words with `overlap`."""
    if not text:
        return []
    words = text.split()
    if len(words) <= chunk_size:
        return [text]
    
    chunks = []
    start = 0
    while start < len(words):
        end = min(start + chunk_size, len(words))
        chunk_words = words[start:end]
        chunks.append(" ".join(chunk_words))
        
        if end == len(words):
            break
            
        start += (chunk_size - overlap)
        
    return chunks

def main():
    # 1. Setup & DB Connection
    if not os.path.exists(DB_PATH):
        print(f"Error: Database not found at '{DB_PATH}'")
        sys.exit(1)
            
    print(f"Using database: {DB_PATH}")
    
    # Check if GPU is available (optional, handled by library but good to know)
    
    print(f"Loading model: {MODEL_NAME}...")
    model = SentenceTransformer(MODEL_NAME)
    print("Model loaded successfully.")

    conn = None
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()

        # 2. Create Table
        print("Creating table ai_search_index...")
        cursor.execute("DROP TABLE IF EXISTS ai_search_index")
        cursor.execute("""
            CREATE TABLE ai_search_index (
                rowid INTEGER PRIMARY KEY AUTOINCREMENT,
                shloka_id TEXT,
                language_code TEXT,
                source_type TEXT,
                chunk_text TEXT,
                embedding TEXT
            )
        """)
        
        # Create an index on shloka_id for faster lookups
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_ai_shloka_id ON ai_search_index (shloka_id)")
        conn.commit()

        # 3. Get all Shlokas
        print("Fetching master shlokas...")
        cursor.execute("SELECT id FROM master_shlokas")
        shloka_ids = [row[0] for row in cursor.fetchall()]
        
        print(f"Found {len(shloka_ids)} shlokas. Starting processing...")

        # 4. Loop & Process
        for shloka_id in tqdm(shloka_ids, desc="Processing Shlokas"):
            # Process for both languages
            for lang in ['en', 'hi']:
                
                # --- PROCESS A: Translation ---
                cursor.execute("""
                    SELECT bhavarth FROM translations 
                    WHERE shloka_id = ? AND language_code = ?
                """, (shloka_id, lang))
                trans_row = cursor.fetchone()
                
                if trans_row and trans_row[0]:
                    bhavarth = trans_row[0].strip()
                    if bhavarth:
                        # Create 1 Chunk
                        text_to_embed = f"Meaning: {bhavarth}"
                        embedding = model.encode(text_to_embed).tolist()
                        
                        cursor.execute("""
                            INSERT INTO ai_search_index (shloka_id, language_code, source_type, chunk_text, embedding)
                            VALUES (?, ?, ?, ?, ?)
                        """, (shloka_id, lang, 'translation', text_to_embed, json.dumps(embedding)))

                # --- PROCESS B: Commentary ---
                cursor.execute("""
                    SELECT content FROM commentaries 
                    WHERE shloka_id = ? AND language_code = ?
                """, (shloka_id, lang))
                comm_rows = cursor.fetchall()
                
                for comm_row in comm_rows:
                    content = comm_row[0]
                    if content:
                        chunks = chunk_text(content)
                        for chunk in chunks:
                            text_to_embed = f"Context: {chunk}"
                            embedding = model.encode(text_to_embed).tolist()
                            
                            cursor.execute("""
                                INSERT INTO ai_search_index (shloka_id, language_code, source_type, chunk_text, embedding)
                                VALUES (?, ?, ?, ?, ?)
                            """, (shloka_id, lang, 'commentary', text_to_embed, json.dumps(embedding)))

        conn.commit()
        print("\nSuccess! Database updated with chunked embeddings.")

    except Exception as e:
        print(f"\nAn error occurred: {e}")
        import traceback
        traceback.print_exc()
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main()
