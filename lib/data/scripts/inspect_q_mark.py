
import json

filepath = "gita_chapter_1_v4.json"
with open(filepath, 'r', encoding='utf-8') as f:
    data = json.load(f)

def check_q_mark(text):
    if isinstance(text, str) and text.strip().startswith('?'):
        print(f"Found: {text[:20]}")
        first_char = text.strip()[0]
        print(f"Char: {first_char} Code: {ord(first_char)}")
        return True
    return False

def recursive_check(data):
    if isinstance(data, dict):
        for key, value in data.items():
            if isinstance(value, str):
                check_q_mark(value)
            else:
                recursive_check(value)
    elif isinstance(data, list):
        for item in data:
            recursive_check(item)

recursive_check(data)
