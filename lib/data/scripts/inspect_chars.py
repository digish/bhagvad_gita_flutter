
import json

filepath = "gita_chapter_1_v4.json"
with open(filepath, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Inspect shloka 1, Bhavarth, Telugu
# Based on previous view_file, it's roughly line 23
# Let's target the exact path
# content -> Bhavarth -> Ramsukhdas -> Telugu

text = data[0]['content']['Bhavarth']['Ramsukhdas']['Telugu']
print(f"Telugu Text: {text[:20]}")
# Print character codes
for char in text[:10]:
    print(f"{char}: {ord(char)} : {hex(ord(char))}")

print("-" * 20)

# Check Hindi which worked
hindi_text = data[0]['content']['Bhavarth']['Ramsukhdas']['Hindi']
# wait, I already cleaned the file in place, so the Hindi one is gone in the file on disk!
# I have to look at the Telugu one which remains.
