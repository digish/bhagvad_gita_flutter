import json
import re
import os

# Regex to match prefixes like "।।1.1।।", "1.1", "1।।", "?1.3।।", "-- 1.30।।", "1.1 - 1.19" and those with U+09F7 (৷)
# Breakdown:
# ^\s*          : Start with optional whitespace
# (?:[?]|--)?   : Optional question mark or double dash
# \s*           : Optional whitespace
# (?:[।।৷]+)?\s* : Optional double danda (Devanagari U+0965 or Bengali U+09F7) and whitespace
# \d+           : Number (Chapter)
# (?:[.]\d+)?   : Optional dot and Number (Shloka)
# (?:\s*-\s*\d+(?:[.]\d+)?)? : Optional range (e.g. - 1.19)
# \s*(?:[।।৷]+)? : Optional whitespace and double danda
# \s*           : Trailing whitespace
PATTERN = re.compile(r'^\s*(?:[?]|--)?\s*(?:[।।৷]+)?\s*\d+(?:[.]\d+)?(?:\s*-\s*\d+(?:[.]\d+)?)?(?:[।।৷]+)?\s*')

def clean_text(text):
    if not isinstance(text, str):
        return text
    # Check if lines start with pattern (sometimes it's just one line, sometimes paragraph)
    # The requirement says "appearing at begining of text". 
    # So we just substitute the pattern at the start of the string once.
    return PATTERN.sub('', text, count=1)

def recursive_clean(data, target_keys):
    """
    Recursively traverse data. If key matches one of target_keys,
    clean its value (or values if it's a dict).
    """
    modified = False
    
    if isinstance(data, dict):
        for key, value in data.items():
            if key in target_keys:
                if isinstance(value, str):
                    new_value = clean_text(value)
                    if new_value != value:
                        data[key] = new_value
                        modified = True
                elif isinstance(value, dict):
                    # If the value is a dictionary (like nested commentaries), we clean its values
                    # We can assume the immediate children of 'Commentaries' or 'Bhavarth' 
                    # might be languages/authors mapping to text.
                    # Actually, for 'Commentaries', it's: "Big Three" -> { "Author": "Text" }
                    # For 'Bhavarth', it's { "Language": "Text" }
                    # So we should recursively process the *values* of this dictionary, 
                    # but we treat everything under these keys as candidates for cleaning 
                    # if they are strings.
                     # But wait, recursive_clean is general.
                     # if key is in target_keys, we want to descend into 'value' and clean all strings found there.
                     # Let's make a helper for specifically fully cleaning a subtree
                     if _clean_subtree(value):
                         modified = True
            else:
                # Continue searching recursively for the keys
                if recursive_clean(value, target_keys):
                    modified = True
    elif isinstance(data, list):
        for item in data:
            if recursive_clean(item, target_keys):
                modified = True
                
    return modified

def _clean_subtree(data):
    """
    Cleans all string values in this subtree (dict or list).
    """
    modified = False
    if isinstance(data, dict):
        for key, value in data.items():
            if isinstance(value, str):
                new_value = clean_text(value)
                if new_value != value:
                    data[key] = new_value
                    modified = True
            else:
                if _clean_subtree(value):
                    modified = True
    elif isinstance(data, list):
        for item in data:
            if _clean_subtree(item):
                modified = True
    return modified

def process_file(filepath):
    print(f"Processing {filepath}...")
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # We are looking for 'Commentaries' and 'Bhavarth' keys.
        target_keys = {'Commentaries', 'Bhavarth'}
        has_changes = recursive_clean(data, target_keys)
        
        if has_changes:
            print(f"  Changes detected. Saving {filepath}...")
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
        else:
            print(f"  No changes needed for {filepath}.")
            
    except Exception as e:
        print(f"  Error processing {filepath}: {e}")

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # Assuming files are in the same directory as this script
    # Files pattern: gita_chapter_x_v4.json (1 to 18)
    
    for i in range(1, 19):
        filename = f"gita_chapter_{i}_v4.json"
        filepath = os.path.join(script_dir, filename)
        if os.path.exists(filepath):
            process_file(filepath)
        else:
            print(f"Warning: File not found: {filepath}")

if __name__ == "__main__":
    main()
