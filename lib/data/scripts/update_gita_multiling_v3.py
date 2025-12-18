import requests
from bs4 import BeautifulSoup
import json
import time
import re
import random
import os

# --- CONFIGURATION ---
DRY_RUN = False  # Set False for full run
TARGET_CHAPTERS = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18] 

INPUT_FILENAME_PATTERN = "gita_chapter_{}.json"
OUTPUT_FILENAME_PATTERN = "gita_chapter_{}_v4.json"
BASE_URL = "https://www.gitasupersite.iitk.ac.in/srimad"

# Regional scripts to fetch for Hindi content
REGIONAL_LANGUAGES = {
    'gu': 'Gujarati',
    'te': 'Telugu',
    'kn': 'Kannada',
    'ta': 'Tamil',
    'bn': 'Bengali',
    'dv': 'Devnagri',
    'ro': 'Romanian',
    }

# Params: Include etgb=1 to ensure English is visible
PARAMS_TEMPLATE = {
    'field_chapter_value': 1,
    'field_nsutra_value': 1,
    'hcrskd': '1',  # Ramsukhdas Commentary
    'hcchi': '1',   # Chinmayananda Commentary
    'htrskd': '1',  # Ramsukhdas Bhavarth
    'etgb': '1',    # English Bhavarth (Gambhirananda)
}

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
}

# Map headers to internal keys
SCRAPE_MAP = {
    "Commentaries": {
        "Ramsukhdas": "Hindi Commentary By Swami Ramsukhdas",
        "Chinmayananda": "Hindi Commentary By Swami Chinmayananda"
    },
    "Bhavarth": {
        "Ramsukhdas": "Hindi Translation By Swami Ramsukhdas",
        "Gambhirananda": "English Translation By Swami Gambirananda" # Explicitly added here
    }
}

def clean_text(text):
    if not text: return ""
    text = re.sub(r'\s+', ' ', text).strip()
    garbage = ["Script Assamese", "Mool Shloka", "Select Language", "Home About"]
    for g in garbage:
        if g in text: return ""
    return text

def fetch_content(chapter, shloka, lang_code):
    """
    Fetches page content for a specific language code.
    """
    params = PARAMS_TEMPLATE.copy()
    params['language'] = lang_code
    params['field_chapter_value'] = chapter
    params['field_nsutra_value'] = shloka
    
    try:
        response = requests.get(BASE_URL, params=params, headers=HEADERS, timeout=10)
        response.raise_for_status()
        soup = BeautifulSoup(response.content, 'html.parser')
        
        extracted = {"Commentaries": {}, "Bhavarth": {}}
        all_bolds = soup.find_all(['b', 'strong'])
        
        for section, authors in SCRAPE_MAP.items():
            for author_key, header_keyword in authors.items():
                
                found_text = ""
                for bold in all_bolds:
                    # Case insensitive matching
                    if header_keyword.lower() in bold.get_text().lower():
                        parent = bold.find_parent('div')
                        if parent:
                            full_text = parent.get_text()
                            content = full_text.replace(bold.get_text(), "").strip()
                            found_text = clean_text(content)
                        break
                
                if found_text:
                    extracted[section][author_key] = found_text
                    
        return extracted

    except Exception as e:
        print(f"    Error fetching {lang_code}: {e}")
        return None

def process_chapter(chapter_idx):
    input_file = INPUT_FILENAME_PATTERN.format(chapter_idx)
    if not os.path.exists(input_file):
        print(f"File not found: {input_file}")
        return

    with open(input_file, 'r', encoding='utf-8') as f:
        old_data = json.load(f)

    new_data = []
    
    for i, entry in enumerate(old_data):
        if DRY_RUN and i >= 2: break
        
        shloka_num = entry['shloka']
        print(f"  Processing {chapter_idx}.{shloka_num}...")

        # --- 1. INITIALIZE NEW STRUCTURE ---
        new_entry = {
            "chapter": entry['chapter'],
            "shloka": entry['shloka'],
            "url_base": entry['url'],
            "content": {
                "Mool Shloka": entry['content'].get('Mool Shloka', ""),
                "Commentaries": {
                    "Big Three": entry['content'].get('Big Three (Original & Translation)', {}),
                    "Modern": {
                        "Sivananda": {},
                        "Ramsukhdas": {},
                        "Chinmayananda": {}
                    }
                },
                "Bhavarth": {
                    "Ramsukhdas": {},
                    "Gambhirananda": {}
                }
            }
        }

        # --- 2. MIGRATE OLD DATA (Static) ---
        old_modern = entry['content'].get('Modern Seeker', {})
        if "Swami Sivananda (English)" in old_modern:
            new_entry["content"]["Commentaries"]["Modern"]["Sivananda"]["English"] = old_modern["Swami Sivananda (English)"]

        # --- 3. FETCH BASE DATA (Hindi & English) ---
        # Fetch with 'dv' (Devanagari) to get the base Hindi and English texts
        base_content = fetch_content(chapter_idx, shloka_num, 'dv')
        
        if base_content:
            # Save English Gambhirananda (Only needed once)
            if "Gambhirananda" in base_content["Bhavarth"]:
                new_entry["content"]["Bhavarth"]["Gambhirananda"]["English"] = base_content["Bhavarth"]["Gambhirananda"]
            else:
                print("    ! Warning: Gambhirananda English not found in base fetch.")

            # Save Base Hindi Texts
            if "Ramsukhdas" in base_content["Bhavarth"]:
                new_entry["content"]["Bhavarth"]["Ramsukhdas"]["Hindi"] = base_content["Bhavarth"]["Ramsukhdas"]
            
            if "Ramsukhdas" in base_content["Commentaries"]:
                new_entry["content"]["Commentaries"]["Modern"]["Ramsukhdas"]["Hindi"] = base_content["Commentaries"]["Ramsukhdas"]
                
            if "Chinmayananda" in base_content["Commentaries"]:
                new_entry["content"]["Commentaries"]["Modern"]["Chinmayananda"]["Hindi"] = base_content["Commentaries"]["Chinmayananda"]

        # --- 4. FETCH REGIONAL SCRIPTS ---
        for lang_code, lang_name in REGIONAL_LANGUAGES.items():
            scraped = fetch_content(chapter_idx, shloka_num, lang_code)
            
            if scraped:
                # Add Regional Commentary (Ramsukhdas)
                if "Ramsukhdas" in scraped["Commentaries"]:
                    new_entry["content"]["Commentaries"]["Modern"]["Ramsukhdas"][lang_name] = scraped["Commentaries"]["Ramsukhdas"]
                
                # Add Regional Commentary (Chinmayananda)
                if "Chinmayananda" in scraped["Commentaries"]:
                    new_entry["content"]["Commentaries"]["Modern"]["Chinmayananda"][lang_name] = scraped["Commentaries"]["Chinmayananda"]
                
                # Add Regional Bhavarth (Ramsukhdas)
                if "Ramsukhdas" in scraped["Bhavarth"]:
                    new_entry["content"]["Bhavarth"]["Ramsukhdas"][lang_name] = scraped["Bhavarth"]["Ramsukhdas"]

            time.sleep(0.3)
            # print(f"    - Fetched {lang_name}")

        new_data.append(new_entry)
        print("-" * 20)

    output_file = OUTPUT_FILENAME_PATTERN.format(chapter_idx)
    if DRY_RUN: output_file = "dry_run_" + output_file
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(new_data, f, ensure_ascii=False, indent=4)
    print(f"Saved {output_file}")

def main():
    if DRY_RUN:
        print("!!! DRY RUN MODE ENABLED !!!")
    for chapter in TARGET_CHAPTERS:
        process_chapter(chapter)

if __name__ == "__main__":
    main()