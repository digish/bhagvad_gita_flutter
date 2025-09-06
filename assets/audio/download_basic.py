import os
import re

folder = "gita_shlokas/Chapter13_audio"

# Regex to match filenames like ch13_sh02.mp3
pattern = re.compile(r"(ch\d+_sh)(\d{2})(\.mp3)")

# Collect matching files and their numbers
files = []
for filename in os.listdir(folder):
    match = pattern.match(filename)
    if match:
        prefix, num_str, suffix = match.groups()
        num = int(num_str)
        files.append((num, filename))

# Sort files by number in ascending order (lowest to highest)
files.sort()

for num, filename in files:
    new_num = num - 1
    if new_num < 1:
        continue  # Skip if result would be zero or negative
    new_num_str = f"{new_num:02d}"
    # Use \g<1> and \g<3> for group references to avoid ambiguity
    new_filename = pattern.sub(rf"\g<1>{new_num_str}\g<3>", filename)
    src = os.path.join(folder, filename)
    dst = os.path.join(folder, new_filename)
    os.rename(src, dst)
    print(f"Renamed: {filename} -> {new_filename}")