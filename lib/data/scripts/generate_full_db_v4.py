import sqlite3
import json
import glob
import os
import re
import unicodedata
from aksharamukha import transliterate

# Configuration
INPUT_JSON_PATTERN = "lib/data/scripts/gita_chapter_*_v4.json"
OUTPUT_DB = "assets/database/geeta_v4.db"

# Script Mapping (Aksharamukha Codes)
# Source is always Devanagari from JSON 'Mool Shloka'
TARGET_SCRIPTS = {
    'en': 'IAST',
    'te': 'Telugu',
    'gu': 'Gujarati',
    'mr': 'Devanagari', # Marathi uses Devanagari
    'bn': 'Bengali',
    'ta': 'Tamil',
    'kn': 'Kannada',
    'dev': 'Devanagari'
}

def normalize_text(text):
    if not text: return ""
    # 1. Custom Replacements
    text = text.replace("ṣ", "sh")
    text = text.replace("ś", "sh")
    text = text.replace("ṛ", "ri")  # kṛṣṇa -> krishna
    text = text.replace("ñ", "n").replace("ṅ", "n").replace("ṇ", "n")
    
    # 2. Strip standard accents (ā -> a, ī -> i)
    text = unicodedata.normalize('NFKD', text).encode('ascii', 'ignore').decode('utf-8')
    return text.lower().strip()

def create_schema(cursor):
    print("Creating schema...")
    
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS master_shlokas (
        id TEXT PRIMARY KEY,        -- "1.1"
        chapter_no INTEGER,
        shloka_no INTEGER,
        speaker TEXT,               -- "Sanjaya", "Arjuna"
        sanskrit_romanized TEXT,    -- IAST
        audio_path TEXT
    )
    """)
    
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS shloka_scripts (
        shloka_id TEXT,
        script_code TEXT,           -- 'dev', 'te', 'gu', 'en'
        shloka_text TEXT,
        anvay_text TEXT,
        FOREIGN KEY(shloka_id) REFERENCES master_shlokas(id),
        PRIMARY KEY (shloka_id, script_code)
    )
    """)
    
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS translations (
        shloka_id TEXT,
        language_code TEXT,         -- 'en', 'hi'
        author TEXT,                -- 'Ramsukhdas'
        bhavarth TEXT,
        FOREIGN KEY(shloka_id) REFERENCES master_shlokas(id),
        PRIMARY KEY (shloka_id, language_code, author)
    )
    """)
    
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS commentaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shloka_id TEXT,
        author_name TEXT,
        language_code TEXT,
        content TEXT,
        FOREIGN KEY(shloka_id) REFERENCES master_shlokas(id)
    )
    """)
    
    cursor.execute("""
    CREATE VIRTUAL TABLE IF NOT EXISTS search_index USING fts4(
        term_original,
        term_romanized,
        ref_id,
        display_text,
        language_code,
        category            -- 'shloka', 'anvay', 'meaning', 'bhavarth', 'navigation'
    )
    """)

def process_data(cursor):
    json_files = sorted(glob.glob(INPUT_JSON_PATTERN))
    print(f"Found {len(json_files)} JSON files.")
    
    count_master = 0
    count_scripts = 0
    count_translations = 0
    count_commentaries = 0

    for json_file in json_files:
        print(f"Processing {json_file}...")
        with open(json_file, 'r', encoding='utf-8') as f:
            chapter_data = json.load(f)
            
            for item in chapter_data:
                chapter = item['chapter']
                shloka_num = item['shloka']
                shloka_id = f"{chapter}.{shloka_num}"
                
                # 1. Master Shlokas
                speaker = item.get('speaker', '')
                audio_path = f"{chapter}_{shloka_num}.mp3"
                
                content = item.get('content', {})
                mool_shloka = content.get('Mool Shloka', '')
                anvay_default = content.get('Anvay', '')
                
                # Generate IAST for master table
                sanskrit_romanized = ""
                if mool_shloka:
                    sanskrit_romanized = transliterate.process('Devanagari', 'IAST', mool_shloka)
                
                cursor.execute("""
                    INSERT OR REPLACE INTO master_shlokas 
                    (id, chapter_no, shloka_no, speaker, sanskrit_romanized, audio_path) 
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (shloka_id, chapter, shloka_num, speaker, sanskrit_romanized, audio_path))
                count_master += 1
                
                # 2. Shloka Scripts
                if mool_shloka:
                    for code, script_name in TARGET_SCRIPTS.items():
                        shloka_text = ""
                        anvay_text = ""
                        
                        if code == 'dev':
                            shloka_text = mool_shloka
                            anvay_text = anvay_default
                        else:
                            shloka_text = transliterate.process('Devanagari', script_name, mool_shloka)
                            if anvay_default:
                                anvay_text = transliterate.process('Devanagari', script_name, anvay_default)
                        
                        cursor.execute("""
                            INSERT OR REPLACE INTO shloka_scripts 
                            (shloka_id, script_code, shloka_text, anvay_text) 
                            VALUES (?, ?, ?, ?)
                        """, (shloka_id, code, shloka_text, anvay_text))
                        count_scripts += 1

                # 3. Translations (Bhavarth)
                if 'Bhavarth' in content:
                    bhavarth_section = content['Bhavarth']
                    for author, languages in bhavarth_section.items():
                        for lang_name, text in languages.items():
                            lang_code = 'en'
                            if lang_name == 'Hindi': lang_code = 'hi'
                            elif lang_name == 'Gujarati': lang_code = 'gu'
                            elif lang_name == 'Telugu': lang_code = 'te'
                            elif lang_name == 'Kannada': lang_code = 'kn'
                            elif lang_name == 'Tamil': lang_code = 'ta'
                            elif lang_name == 'Bengali': lang_code = 'bn'
                            elif lang_name == 'Romanian': lang_code = 'ro'
                            elif lang_name == 'English': lang_code = 'en'
                            elif lang_name == 'Sanskrit': lang_code = 'sa'
                            
                            if lang_name == 'Devnagri': continue
                            
                            if text:
                                cursor.execute("""
                                    INSERT OR REPLACE INTO translations 
                                    (shloka_id, language_code, author, bhavarth) 
                                    VALUES (?, ?, ?, ?)
                                """, (shloka_id, lang_code, author, text))
                                count_translations += 1

                # 4. Commentaries
                if 'Commentaries' in content:
                    commentaries_section = content['Commentaries']
                    
                    # Handle nested structure or flat structure
                    # Logic adapted from create_v2_db.py but simplified if structure is consistent
                    # Assuming the structure observed in V4 JSONs:
                    
                    for group_name, authors_dict in commentaries_section.items():
                        # authors_dict can be a dict of authors or direct keys
                        if isinstance(authors_dict, dict):
                            for key, value in authors_dict.items():
                                if isinstance(value, dict):
                                    # Nested: "Sivananda": {"English": "..."}
                                    author_name = key
                                    for lang_name, text in value.items():
                                        if lang_name == 'Devnagri': continue
                                        
                                        lang_code = 'en'
                                        if lang_name == 'Hindi': lang_code = 'hi'
                                        elif lang_name == 'English': lang_code = 'en'
                                        elif lang_name == 'Sanskrit': lang_code = 'sa'
                                        elif lang_name == 'Gujarati': lang_code = 'gu'
                                        elif lang_name == 'Telugu': lang_code = 'te'
                                        elif lang_name == 'Tamil': lang_code = 'ta'
                                        elif lang_name == 'Bengali': lang_code = 'bn'
                                        elif lang_name == 'Kannada': lang_code = 'kn'
                                        elif lang_name == 'Romanian': lang_code = 'ro'
                                        
                                        if text:
                                            cursor.execute("INSERT INTO commentaries (shloka_id, author_name, language_code, content) VALUES (?, ?, ?, ?)",
                                                        (shloka_id, author_name, lang_code, text))
                                            count_commentaries += 1
                                elif isinstance(value, str):
                                    # Flat: "Shankaracharya (Sanskrit)": "..."
                                    raw_key = key
                                    text = value
                                    author_name = raw_key
                                    lang_code = 'en'
                                    
                                    if '(' in raw_key and ')' in raw_key:
                                        author_name = raw_key.split('(')[0].strip()
                                        lang_str = raw_key.split('(')[1].split(')')[0].strip()
                                        if 'Hindi' in lang_str: lang_code = 'hi'
                                        elif 'Sanskrit' in lang_str: lang_code = 'sa'
                                        elif 'English' in lang_str: lang_code = 'en'
                                    
                                    if text:
                                        cursor.execute("INSERT INTO commentaries (shloka_id, author_name, language_code, content) VALUES (?, ?, ?, ?)",
                                                    (shloka_id, author_name, lang_code, text))
                                        count_commentaries += 1

    print(f"Inserted {count_master} master shlokas.")
    print(f"Inserted {count_scripts} script entries.")
    print(f"Inserted {count_translations} translations.")
    print(f"Inserted {count_commentaries} commentaries.")

def populate_search_index(cursor):
    print("Populating Search Index...")
    
    # Navigation
    cursor.execute("SELECT id, chapter_no, shloka_no FROM master_shlokas")
    rows = cursor.fetchall()
    for row in rows:
        shloka_id, ch, sl = row
        term = f"{ch}.{sl}"
        display = f"Chapter {ch}, Verse {sl}"
        cursor.execute("INSERT INTO search_index (term_original, term_romanized, ref_id, display_text, language_code, category) VALUES (?, ?, ?, ?, ?, ?)",
                       (term, term, shloka_id, display, 'en', 'navigation'))

    # Shloka / Anvay
    # Use 'shloka_scripts' to get text in various scripts
    # For normalization/romanization, we use the DEVANAGARI source converted to IAST, OR verify if script provides better source
    # We will iterate master_shlokas to get IAST source for normalization if needed, or just iterate shloka_scripts
    
    cursor.execute("SELECT shloka_id, script_code, shloka_text, anvay_text FROM shloka_scripts")
    rows = cursor.fetchall()
    
    for row in rows:
        shloka_id, code, shloka, anvay = row
        
        # Process Shloka
        if shloka:
            words = re.split(r'[\s\u0964\u0965,\-\?\!\.\(\)"]+', shloka)
            for word in words:
                clean_word = word.strip("।,-?!\"'()")
                if not clean_word: continue
                
                # Normalize logic:
                # 1. Start with clean_word (could be Tel/Guj/Dev)
                # 2. Convert to IAST for normalization (unless it's already latin)
                # 3. Apply normalize_text
                
                term_romanized = ""
                if code == 'en': # IAST
                    term_romanized = clean_word
                elif code == 'dev':
                    term_romanized = transliterate.process('Devanagari', 'IAST', clean_word)
                else:
                    # Convert from Target Script back to IAST? Or Devanagari to IAST?
                    # Transliteration is expensive.
                    # Best approach: Since we have the Devanagari/IAST versions in the same DB,
                    # We could just index the transliterated words. 
                    # But the user might search "krishna" and expect matches from Gujarati text.
                    # So we need to map the Gujarati word to "krishna".
                    
                    # Since we generated these FRom Devanagari using Aksharamukha, 
                    # we can usually assume reliable transliteration.
                    # But reverse transliteration (Guj -> IAST) is also supported by Aksharamukha.
                    src_script = TARGET_SCRIPTS.get(code, 'Devanagari')
                    try:
                        term_romanized = transliterate.process(src_script, 'IAST', clean_word)
                    except:
                        term_romanized = clean_word # Fallback
                
                term_norm = normalize_text(term_romanized)
                
                cursor.execute("INSERT INTO search_index (term_original, term_romanized, ref_id, display_text, language_code, category) VALUES (?, ?, ?, ?, ?, ?)",
                               (clean_word, term_norm, shloka_id, f"Shloka {shloka_id}: {clean_word}", code, 'shloka'))

        # Process Anvay (Similar)
        if anvay:
             words = re.split(r'[\s\u0964\u0965,\-\?\!\.\(\)"]+', anvay)
             for word in words:
                clean_word = word.strip("।,-?!\"'()")
                if not clean_word: continue
                
                term_romanized = ""
                if code == 'en':
                    term_romanized = clean_word
                elif code == 'dev':
                    term_romanized = transliterate.process('Devanagari', 'IAST', clean_word)
                else:
                    src_script = TARGET_SCRIPTS.get(code, 'Devanagari')
                    try:
                        term_romanized = transliterate.process(src_script, 'IAST', clean_word)
                    except:
                        term_romanized = clean_word
                
                term_norm = normalize_text(term_romanized)
                
                cursor.execute("INSERT INTO search_index (term_original, term_romanized, ref_id, display_text, language_code, category) VALUES (?, ?, ?, ?, ?, ?)",
                               (clean_word, term_norm, shloka_id, f"Anvay {shloka_id}: {clean_word}", code, 'anvay'))


    # English Meaning (Commentaries) & Bhavarth
    stop_words = {"is", "are", "was", "were", "the", "a", "an", "and", "or", "of", "to", "in", "on", "at", "for", "by", "with", "from", "that", "this", "it", "i", "am", "me", "my", "you", "your", "he", "she", "his", "her", "they", "them", "their", "we", "us", "our", "be", "been", "being", "have", "has", "had", "do", "does", "did", "not", "but", "so", "as", "if", "when", "then", "than", "about", "into", "over", "after", "before", "up", "down", "out", "off", "all", "any", "some", "no", "can", "could", "will", "would", "shall", "should", "may", "might", "must"}

    cursor.execute("SELECT shloka_id, content FROM commentaries WHERE language_code='en'")
    for row in cursor.fetchall():
        shloka_id, content = row
        words = re.split(r'[\s,\.\?\!\(\)\"\']+', content)
        for word in  set(words):
            clean = word.lower().strip(".,?!\"'()")
            if clean and clean not in stop_words and len(clean) > 2:
                 cursor.execute("INSERT INTO search_index (term_original, term_romanized, ref_id, display_text, language_code, category) VALUES (?, ?, ?, ?, ?, ?)",
                               (word, clean, shloka_id, f"Meaning {shloka_id}", 'en', 'meaning'))
                               
    cursor.execute("SELECT shloka_id, bhavarth FROM translations WHERE language_code='en'")
    for row in cursor.fetchall():
        shloka_id, bhavarth = row
        if not bhavarth: continue
        words = re.split(r'[\s,\.\?\!\(\)\"\']+', bhavarth)
        for word in  set(words):
            clean = word.lower().strip(".,?!\"'()")
            if clean and clean not in stop_words and len(clean) > 2:
                 cursor.execute("INSERT INTO search_index (term_original, term_romanized, ref_id, display_text, language_code, category) VALUES (?, ?, ?, ?, ?, ?)",
                               (word, clean, shloka_id, f"Translation {shloka_id}", 'en', 'bhavarth'))

def main():
    if os.path.exists(OUTPUT_DB):
        os.remove(OUTPUT_DB)
        
    conn = sqlite3.connect(OUTPUT_DB)
    cursor = conn.cursor()
    
    try:
        create_schema(cursor)
        process_data(cursor)
        populate_search_index(cursor)
        conn.commit()
        print(f"Successfully created {OUTPUT_DB}")
    except Exception as e:
        print(f"Error: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    main()
