import requests
from bs4 import BeautifulSoup
import json
import time
import re
import random  # Import random for variable sleep

# --- CONFIGURATION ---
TARGET_CHAPTERS = [18] # Change this to list(range(1, 19)) for full download
OUTPUT_FILENAME_PATTERN = "gita_chapter_{}.json"
BASE_URL = "https://www.gitasupersite.iitk.ac.in/srimad"

SHLOKA_COUNTS = [
    47, 72, 43, 42, 29, 47, 30, 28, 34, 42, 55, 20, 34, 27, 20, 24, 28, 78
]

PARAMS = {
    'language': 'dv',
    'scsh': '1', 'setgb': '1', 
    'scram': '1', 'etradi': '1', 
    'scmad': '1', 
    'hcrskd': '1', 'hcchi': '1', 
    'ecsiva': '1'
}

# FAKE A BROWSER (Crucial to avoid blocks)
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9"
}

STRUCTURED_MAP = {
    "Big Three (Original & Translation)": {
        "Shankaracharya (Sanskrit)": "Sanskrit Commentary By Sri Shankaracharya",
        "Shankaracharya (English)": "Gambirananda", 
        "Ramanujacharya (Sanskrit)": "Sanskrit Commentary By Sri Ramanuja",
        "Ramanujacharya (English)": "Adidevananda",
        "Madhvacharya (Sanskrit)": "Sanskrit Commentary By Sri Madhvacharya" 
    },
    "Modern Seeker": {
        "Swami Ramsukhdas (Hindi)": "Ramsukhdas",
        "Swami Chinmayananda (Hindi)": "Chinmayananda",
        "Swami Sivananda (English)": "Sivananda"
    }
}

def clean_text(text):
    if not text: return ""
    text = re.sub(r'\s+', ' ', text).strip()
    
    garbage_indicators = ["Script Assamese", "Mool Shloka", "Home About Website", "Select Language"]
    for garbage in garbage_indicators:
        if garbage in text: return "" 
    return text

def clean_madhva_content(text):
    if not text: return ""
    text = re.sub(r"Sanskrit Commentary By Sri Madh?avacharya", "", text, flags=re.IGNORECASE)
    return clean_text(text)

def fetch_shloka(chapter, shloka):
    current_params = PARAMS.copy()
    current_params['field_chapter_value'] = chapter
    current_params['field_nsutra_value'] = shloka
    
    try:
        # Pass HEADERS here to look like a browser
        response = requests.get(BASE_URL, params=current_params, headers=HEADERS, timeout=15)
        response.raise_for_status()
        soup = BeautifulSoup(response.content, 'html.parser')
        
        shloka_data = {
            "chapter": chapter,
            "shloka": shloka,
            "url": response.url,
            "content": {
                "Mool Shloka": "",
                "Big Three (Original & Translation)": {},
                "Modern Seeker": {}
            }
        }
        
        mool_div = soup.find('div', class_='views-field-field-mool-shloka')
        if mool_div:
            shloka_data["content"]["Mool Shloka"] = clean_text(mool_div.get_text())

        all_bolds = soup.find_all(['b', 'strong'])
        
        for category, commentators in STRUCTURED_MAP.items():
            for display_name, keyword in commentators.items():
                found_text = ""
                
                # Madhvacharya Handler
                if display_name == "Madhvacharya (Sanskrit)":
                    madhva_container = soup.find('div', class_=re.compile(r'field-scmad'))
                    if madhva_container:
                        found_text = clean_madhva_content(madhva_container.get_text())
                    if found_text:
                        shloka_data["content"][category][display_name] = found_text
                    continue 
                
                # Standard Handler
                for bold_tag in all_bolds:
                    if keyword.lower() in bold_tag.get_text().lower():
                        parent = bold_tag.find_parent('div')
                        if parent:
                            full_text = parent.get_text()
                            found_text = full_text.replace(bold_tag.get_text(), "").strip()
                            found_text = clean_text(found_text)
                        break 
                
                if found_text:
                    shloka_data["content"][category][display_name] = found_text
        
        return shloka_data

    except Exception as e:
        print(f"Error fetching Ch {chapter} Sh {shloka}: {e}")
        return None

def main():
    print(f"Starting SAFE download for Chapters: {TARGET_CHAPTERS}")
    
    for chapter_idx in TARGET_CHAPTERS:
        if chapter_idx < 1 or chapter_idx > 18: continue

        count = SHLOKA_COUNTS[chapter_idx - 1]
        chapter_data = []
        
        print(f"--- Processing Chapter {chapter_idx} ({count} shlokas) ---")
        
        for shloka_num in range(1, count + 1):
            data = fetch_shloka(chapter_idx, shloka_num)
            if data:
                chapter_data.append(data)
                print(f"  Saved {chapter_idx}.{shloka_num}")
            else:
                print(f"  Failed {chapter_idx}.{shloka_num}")
            
            # --- SAFETY DELAY ---
            # Random wait between 2.0 and 4.0 seconds
            delay = random.uniform(2.0, 4.0)
            # print(f"    Sleeping {delay:.2f}s...") 
            time.sleep(delay) 

        filename = OUTPUT_FILENAME_PATTERN.format(chapter_idx)
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(chapter_data, f, ensure_ascii=False, indent=4)
        
        print(f"Completed Chapter {chapter_idx}. Saved to '{filename}'.")
        print("-" * 30)

if __name__ == "__main__":
    main()