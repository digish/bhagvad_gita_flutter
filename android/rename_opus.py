import os
import re

# --- Configuration ---

# 1. ⚠️ SAFETY SWITCH:
#    True = Show what will be renamed without touching any files.
#    False = Perform the actual renaming.
DRY_RUN = False

# ---------------------

def process_chapter_directory(directory_path):
    """
    Scans a directory for non-padded, 0-indexed shloka files (e.g., ch01_sh0.opus)
    and renames them back to a padded, 1-indexed format (e.g., ch01_sh01.opus).
    """
    if not os.path.isdir(directory_path):
        print(f"🟡 Skipping: Directory not found -> {directory_path}")
        return

    print(f"\n✅ Processing Directory: {directory_path}")
    
    # Regex to find files with non-padded shloka numbers.
    filename_pattern = re.compile(r'^(ch\d{2}_sh)(\d+)(\.opus)$')
    files_to_process = []

    for filename in os.listdir(directory_path):
        match = filename_pattern.match(filename)
        if match:
            try:
                shloka_num = int(match.group(2))
                files_to_process.append({
                    "original_path": os.path.join(directory_path, filename),
                    "shloka_num": shloka_num,
                    "prefix": match.group(1),
                    "extension": match.group(3),
                })
            except (ValueError, IndexError):
                continue
    
    if not files_to_process:
        print("  -> No files found to rename (already in original format?).")
        return

    # CRITICAL: Sort in descending order to avoid overwriting files.
    files_to_process.sort(key=lambda x: x["shloka_num"], reverse=True)

    for file_info in files_to_process:
        # The new filename will be 1-indexed and zero-padded.
        new_shloka_num = file_info["shloka_num"] + 1
        new_filename = f"{file_info['prefix']}{new_shloka_num:02d}{file_info['extension']}"
        new_path = os.path.join(os.path.dirname(file_info["original_path"]), new_filename)
        
        original_filename = os.path.basename(file_info["original_path"])

        print(f"  -> Plan: Rename '{original_filename}' TO '{new_filename}'")
        
        if not DRY_RUN:
            try:
                os.rename(file_info["original_path"], new_path)
            except OSError as e:
                print(f"    ❌ ERROR: Could not rename file. Reason: {e}")

if __name__ == "__main__":
    print("--- Starting Shloka Reverting Script for All Chapters ---")
    if DRY_RUN:
        print("⚠️ DRY RUN MODE IS ON. No files will be renamed.")
    else:
        print("🔴 LIVE MODE IS ON. Files will actually be renamed.")

    for i in range(1, 19): # Chapters 1 to 18
        chapter_assets_path = os.path.join(f"Chapter{i}_audio", "src", "main", "assets")
        process_chapter_directory(chapter_assets_path)

    print("\n" + "="*50)
    print("--- Script finished for all chapters. ---")
    if DRY_RUN:
        print("👍 Review the plan above. If it looks correct, set DRY_RUN = False and run the script again.")